export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const body = (await readBody<{ message_id?: number } | null>(event)) ?? {}
  const chat = await loadChat(user.id)
  if (chat.conversation) {
    const latest = chat.messages.at(-1)?.id ?? 0
    chat.conversation.customer_last_read = Math.max(chat.conversation.customer_last_read, Math.min(body.message_id || latest, latest))
    await saveChat(user.id, chat)
  }
  return { unread: unreadCount(chat) }
})
