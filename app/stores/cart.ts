import { defineStore } from 'pinia'
import type { OrderItem, ProductSummary, Quote, Variant } from '#shared/types/api'

export const CART_STORAGE_KEY = 'rk_cart_v1'

/** A cart line keeps a snapshot of the product so the cart renders offline. */
export interface CartLine {
  sku: string
  slug: string
  qty: number
  name: string
  variant_label: string
  emoji: string
  color: string
  image: string | null
  price: number
  original_price: number
  sold_by_weight: boolean
  step: number
  min: number
  max: number
}

const round = (n: number) => Math.round(n * 1000) / 1000

export const useCartStore = defineStore('cart', () => {
  const lines = ref<CartLine[]>([])
  const coupon = ref<string | null>(null)
  const loaded = ref(false)

  const count = computed(() => lines.value.length)
  const estimate = computed(() => roundMoney(lines.value.reduce((sum, l) => sum + l.price * l.qty, 0)))

  const find = (sku: string) => lines.value.find((l) => l.sku === sku)
  const qtyOf = (sku: string) => find(sku)?.qty ?? 0

  /** Returns false when the max quantity was already reached. */
  function add(product: ProductSummary, variant?: Variant): boolean {
    const v = variant ?? product.variants.find((x) => x.sku === product.default_sku) ?? product.variants[0]
    if (!v || !v.in_stock) return false
    const existing = find(v.sku)
    if (existing) return increment(v.sku)
    lines.value.push({
      sku: v.sku,
      slug: product.slug,
      qty: Math.min(product.min_qty, v.max_qty),
      name: product.name,
      variant_label: v.label,
      emoji: product.emoji,
      color: product.color,
      image: product.image,
      price: v.sale_price ?? v.price,
      original_price: v.price,
      sold_by_weight: product.sold_by_weight,
      step: product.qty_step,
      min: product.min_qty,
      max: v.max_qty,
    })
    return true
  }

  function increment(sku: string): boolean {
    const line = find(sku)
    if (!line) return false
    if (line.qty + line.step > line.max + 1e-9) return false
    line.qty = round(line.qty + line.step)
    return true
  }

  function decrement(sku: string) {
    const line = find(sku)
    if (!line) return
    const next = round(line.qty - line.step)
    if (next < line.min - 1e-9) remove(sku)
    else line.qty = next
  }

  function remove(sku: string) {
    lines.value = lines.value.filter((l) => l.sku !== sku)
  }

  function clear() {
    lines.value = []
    coupon.value = null
  }

  /** Adds the items of a past order back to the cart ("Order again"). */
  function addFromOrder(items: OrderItem[]) {
    for (const item of items) {
      const existing = find(item.sku)
      if (existing) {
        existing.qty = Math.min(existing.max, round(existing.qty + item.qty))
        continue
      }
      lines.value.push({
        sku: item.sku,
        slug: item.slug,
        qty: item.qty,
        name: item.name,
        variant_label: item.variant_label,
        emoji: item.emoji,
        color: item.color,
        image: item.image,
        price: item.unit_price,
        original_price: item.unit_price,
        sold_by_weight: item.sold_by_weight,
        step: item.sold_by_weight ? 0.25 : 1,
        min: item.sold_by_weight ? 0.5 : 1,
        max: item.sold_by_weight ? 5 : 20,
      })
    }
  }

  /** Refreshes snapshots with server prices, names and limits. */
  function syncFromQuote(quote: Quote) {
    for (const ql of quote.lines) {
      const line = find(ql.sku)
      if (!line) continue
      line.name = ql.product.name
      line.variant_label = ql.variant_label
      line.price = ql.unit_price
      line.original_price = ql.original_unit_price
      line.max = ql.max_qty
      if (ql.available && ql.qty !== line.qty) line.qty = ql.qty
    }
  }

  function load() {
    try {
      const raw = localStorage.getItem(CART_STORAGE_KEY)
      const data = raw ? JSON.parse(raw) : null
      lines.value = Array.isArray(data?.lines) ? data.lines : []
      coupon.value = typeof data?.coupon === 'string' ? data.coupon : null
    } catch {
      lines.value = []
    }
    loaded.value = true
  }

  function persist() {
    try {
      localStorage.setItem(CART_STORAGE_KEY, JSON.stringify({ lines: lines.value, coupon: coupon.value }))
    } catch {
      // Storage full or blocked: the cart still works for this session.
    }
  }

  return { lines, coupon, loaded, count, estimate, find, qtyOf, add, increment, decrement, remove, clear, addFromOrder, syncFromQuote, load, persist }
})
