import type { QuoteRequest } from '#shared/types/api'

// Prices the cart on the server: stock, sale prices, coupon, delivery fee.
export default defineEventHandler(async (event) => {
  const body = await readBody<QuoteRequest>(event)
  return buildQuote({ items: Array.isArray(body?.items) ? body.items : [], coupon: body?.coupon, zone: body?.zone, method: body?.method }, getLang(event))
})
