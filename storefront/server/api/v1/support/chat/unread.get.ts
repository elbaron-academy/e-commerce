export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  return { unread: unreadCount(await loadChat(user.id)) }
})
