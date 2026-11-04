import type { OrderCreateInput, OrderCreateResponse } from '#shared/types/api'
import type { StoredOrder } from '../../../utils/mock-store'

// Checkout (BE-502). The real backend also reserves stock for 15 minutes (BE-503).
export default defineEventHandler(async (event): Promise<OrderCreateResponse> => {
  const user = await requireUser(event)
  const lang = getLang(event)
  const body = await readBody<OrderCreateInput>(event)
  const fail = (statusCode: number, detail: string, extra: Record<string, unknown> = {}) =>
    createError({ statusCode, data: { detail, ...extra } })

  if (!Array.isArray(body?.items) || !body.items.length) throw fail(400, 'Your cart is empty.')
  if (body.method !== 'delivery' && body.method !== 'pickup') throw fail(400, 'Choose a delivery method.')
  if (!['cod', 'card', 'wallet'].includes(body.payment_method)) throw fail(400, 'Choose a payment method.')

  let address = null
  if (body.method === 'delivery') {
    address = (await listAddresses(user.id)).find((a) => a.id === body.address_id) ?? null
    if (!address) throw fail(400, 'Choose a delivery address.', { field: 'address_id' })
  }
  const slot = body.slot_id ? findSlot(body.slot_id) : null
  if (!slot || !slot.available) throw fail(400, 'Choose an available time slot.', { field: 'slot_id' })

  const quote = buildQuote({ items: body.items, coupon: body.coupon, zone: address?.zone, method: body.method }, lang)
  if (!quote.can_checkout) throw fail(409, quote.warnings[0]?.message ?? 'Please review your cart.', { quote })
  if (body.coupon && !quote.coupon?.valid) throw fail(400, quote.coupon?.message ?? 'Invalid coupon.', { field: 'coupon' })
  if (body.payment_method === 'cod' && !quote.cod_available) throw fail(400, `Cash on delivery is available up to EGP ${quote.cod_limit}.`)

  const id = await nextOrderId()
  const now = new Date().toISOString()
  const paysOnline = body.payment_method !== 'cod'
  const stored: StoredOrder = {
    id,
    number: `RK-${String(id).padStart(6, '0')}`,
    created_at: now,
    method: body.method,
    payment_method: body.payment_method,
    payment_status: paysOnline ? 'pending' : 'cod',
    items: quote.lines.map((l) => ({
      sku: l.sku,
      slug: l.product.slug,
      name: l.product.name,
      variant_label: l.variant_label,
      emoji: l.product.emoji,
      color: l.product.color,
      image: l.product.image,
      qty: l.qty,
      unit_price: l.unit_price,
      line_total: l.line_total,
      sold_by_weight: l.product.sold_by_weight,
    })),
    subtotal: quote.subtotal,
    coupon_discount: quote.coupon_discount,
    delivery_fee: quote.delivery_fee,
    total: quote.total,
    coupon: quote.coupon?.valid ? quote.coupon.code : null,
    notes: String(body.notes || '').slice(0, 300),
    address,
    slot: { date: slot.date, start: slot.start, end: slot.end, express: slot.express },
    state: paysOnline ? 'pending_payment' : 'active',
    placed_at: paysOnline ? null : now,
  }
  await saveOrders(user.id, [...(await listOrders(user.id)), stored])
  setResponseStatus(event, 201)
  return { order: presentOrder(stored), payment_url: paysOnline ? `/payment/mock?order=${id}` : null }
})
