export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const query = getQuery(event)
  const num = (v: unknown) => (v === undefined || v === '' ? undefined : Number(v))
  return chatState(await loadChat(user.id), { after: num(query.after), before: num(query.before) })
})
