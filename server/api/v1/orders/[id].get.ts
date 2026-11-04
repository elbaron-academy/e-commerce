export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const id = Number(getRouterParam(event, 'id'))
  const order = (await listOrders(user.id)).find((o) => o.id === id)
  if (!order) throw createError({ statusCode: 404, data: { detail: 'Order not found.' } })
  return presentOrder(order)
})
