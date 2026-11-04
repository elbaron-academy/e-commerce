// Stands in for the payment gateway webhook (BE-504).
export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const { order_id, result } = await readBody<{ order_id: number; result: 'success' | 'failed' }>(event)
  const orders = await listOrders(user.id)
  const order = orders.find((o) => o.id === Number(order_id))
  if (!order) throw createError({ statusCode: 404, data: { detail: 'Order not found.' } })
  if (order.state === 'pending_payment') {
    if (result === 'success') {
      order.state = 'active'
      order.payment_status = 'paid'
      order.placed_at = new Date().toISOString()
    } else {
      order.state = 'cancelled'
      order.payment_status = 'failed'
    }
    await saveOrders(user.id, orders)
  }
  return presentOrder(order)
})
