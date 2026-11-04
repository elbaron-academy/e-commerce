import type { Lang, Quote, QuoteLine, QuoteRequest, QuoteWarning } from '#shared/types/api'
import { roundMoney } from '#shared/utils/text'
import { COUPONS, STORE_RULES, ZONES } from './catalog-data'
import { findSku, serializeProduct, tr } from './catalog'

/** Rounds a requested quantity to the product's step and minimum. */
function normalizeQty(qty: number, soldByWeight: boolean) {
  const n = Number(qty) || 0
  if (soldByWeight) return Math.max(0.5, Math.round(n / 0.25) * 0.25)
  return Math.max(1, Math.round(n))
}

export function buildQuote(input: QuoteRequest, lang: Lang): Quote {
  const lines: QuoteLine[] = []
  const warnings: QuoteWarning[] = []
  let unavailable = false
  let changed = false
  let reduced = false

  for (const item of input.items ?? []) {
    const hit = findSku(String(item.sku))
    if (!hit) {
      unavailable = true
      continue
    }
    const product = serializeProduct(hit.product, lang)
    const variant = product.variants[hit.index]!
    const unit = variant.sale_price ?? variant.price
    let qty = normalizeQty(item.qty, product.sold_by_weight)
    if (variant.in_stock && qty > variant.max_qty) {
      qty = variant.max_qty
      reduced = true
    }
    if (!variant.in_stock) unavailable = true
    const priceChanged = item.expected_price != null && Math.abs(Number(item.expected_price) - unit) > 0.001
    if (priceChanged) changed = true
    lines.push({
      sku: variant.sku,
      qty,
      available: variant.in_stock,
      max_qty: variant.max_qty,
      unit_price: unit,
      original_unit_price: variant.price,
      line_total: variant.in_stock ? roundMoney(unit * qty) : 0,
      price_changed: priceChanged,
      variant_label: variant.label,
      product,
    })
  }

  const available = lines.filter((l) => l.available)
  const subtotal = roundMoney(available.reduce((s, l) => s + l.line_total, 0))
  const savings = roundMoney(available.reduce((s, l) => s + (l.original_unit_price - l.unit_price) * l.qty, 0))

  // Coupon: one per order (BE-404)
  let coupon: Quote['coupon'] = null
  let couponDiscount = 0
  let freeByCoupon = false
  if (input.coupon) {
    const code = String(input.coupon).trim().toUpperCase()
    const rule = COUPONS[code]
    if (!rule) {
      coupon = { code, valid: false, message: tr(['الكود ده مش صحيح أو انتهى', 'This code is invalid or has expired'], lang) }
    } else if (subtotal < rule.min) {
      coupon = {
        code,
        valid: false,
        message: lang === 'ar' ? `الكود ده للطلبات فوق ${rule.min} ج.م` : `This code needs a minimum order of EGP ${rule.min}`,
      }
    } else {
      if (rule.type === 'percent') couponDiscount = Math.min(rule.max ?? Infinity, roundMoney((subtotal * rule.value) / 100))
      if (rule.type === 'fixed') couponDiscount = Math.min(subtotal, rule.value)
      if (rule.type === 'free_delivery') freeByCoupon = true
      coupon = {
        code,
        valid: true,
        message: freeByCoupon
          ? tr(['تم تطبيق الكود: توصيل مجاني', 'Code applied: free delivery'], lang)
          : tr(['تم تطبيق الكود', 'Code applied'], lang),
      }
    }
  }

  const method = input.method ?? 'delivery'
  const zone = ZONES.find((z) => z.id === (input.zone || STORE_RULES.defaultZone)) ?? ZONES[0]!
  const reachedFree = subtotal >= STORE_RULES.freeDeliveryThreshold
  const deliveryFee = method === 'pickup' || reachedFree || freeByCoupon || subtotal === 0 ? 0 : zone.fee
  const total = roundMoney(Math.max(0, subtotal - couponDiscount) + deliveryFee)

  if (unavailable) warnings.push({ code: 'unavailable', message: tr(['فيه منتجات مش متوفرة دلوقتي، شيلها عشان تكمل الطلب.', 'Some items are out of stock. Remove them to continue.'], lang) })
  if (reduced) warnings.push({ code: 'qty_reduced', message: tr(['قللنا كمية بعض المنتجات حسب المتاح.', 'We reduced some quantities to what is available.'], lang) })
  if (changed) warnings.push({ code: 'price_changed', message: tr(['أسعار بعض المنتجات اتغيرت من وقت ما ضفتها.', 'Some prices changed since you added the items.'], lang) })
  if (subtotal > 0 && subtotal < STORE_RULES.minOrder) {
    warnings.push({
      code: 'min_order',
      message: lang === 'ar' ? `الحد الأدنى للطلب ${STORE_RULES.minOrder} ج.م` : `Minimum order is EGP ${STORE_RULES.minOrder}`,
    })
  }

  return {
    lines,
    items_count: lines.length,
    subtotal,
    savings,
    coupon_discount: couponDiscount,
    delivery_fee: deliveryFee,
    total,
    min_order: STORE_RULES.minOrder,
    free_delivery_threshold: STORE_RULES.freeDeliveryThreshold,
    remaining_for_free_delivery: roundMoney(Math.max(0, STORE_RULES.freeDeliveryThreshold - subtotal)),
    cod_available: total <= STORE_RULES.codLimit,
    cod_limit: STORE_RULES.codLimit,
    coupon,
    warnings,
    can_checkout: lines.length > 0 && !unavailable && subtotal >= STORE_RULES.minOrder,
  }
}
