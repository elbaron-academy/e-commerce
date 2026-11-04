export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const orders = (await listOrders(user.id)).map(presentOrder).sort((a, b) => b.id - a.id)
  return { count: orders.length, next: null, previous: null, results: orders }
})
