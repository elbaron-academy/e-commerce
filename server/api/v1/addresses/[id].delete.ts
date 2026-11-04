export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const id = Number(getRouterParam(event, 'id'))
  const list = (await listAddresses(user.id)).filter((a) => a.id !== id)
  if (list.length && !list.some((a) => a.is_default)) list[0]!.is_default = true
  await saveAddresses(user.id, list)
  setResponseStatus(event, 204)
  return null
})
