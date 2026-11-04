import type { ChatConversationRef, ChatMessage, ChatState, Lang } from '#shared/types/api'

// Mock support chat: same contract as Django's /support/chat/. A demo "Rocket team"
// reply arrives a few seconds after the customer writes.
const db = () => useStorage('data')
const PAGE = 30
const REPLY_AFTER_MS = 2500

interface StoredChat {
  conversation: ChatConversationRef | null
  messages: ChatMessage[]
  replyDueAt: number | null
  replyLang: Lang
}

const DEMO_REPLY: Record<Lang, string> = {
  ar: 'أهلاً بيك! 👋 ده رد تجريبي من فريق روكت. في النسخة الحقيقية حد من فريق الدعم هيرد عليك هنا.',
  en: "Hi! 👋 This is a demo reply from the Rocket team. In the live store a real person answers here.",
}

async function nextId() {
  const id = ((await db().getItem<number>('mock:chat_seq')) ?? 0) + 1
  await db().setItem('mock:chat_seq', id)
  return id
}

export async function loadChat(userId: number): Promise<StoredChat> {
  const chat = (await db().getItem<StoredChat>(`mock:chat:${userId}`)) ?? {
    conversation: null,
    messages: [],
    replyDueAt: null,
    replyLang: 'ar',
  }
  // Deliver the demo reply once it's due.
  if (chat.replyDueAt && chat.replyDueAt <= Date.now() && chat.conversation) {
    const lastCustomer = [...chat.messages].reverse().find((m) => m.sender === 'customer')
    chat.conversation.staff_last_read = lastCustomer?.id ?? 0
    chat.messages.push({
      id: await nextId(),
      conversation: chat.conversation.id,
      kind: 'text',
      event: '',
      sender: 'staff',
      sender_name: 'Rocket',
      body: DEMO_REPLY[chat.replyLang],
      image: null,
      order: null,
      created_at: new Date().toISOString(),
    })
    chat.replyDueAt = null
    await saveChat(userId, chat)
  }
  return chat
}

export async function saveChat(userId: number, chat: StoredChat) {
  await db().setItem(`mock:chat:${userId}`, chat)
}

export function unreadCount(chat: StoredChat) {
  const read = chat.conversation?.customer_last_read ?? 0
  return chat.messages.filter((m) => m.sender === 'staff' && m.kind === 'text' && m.id > read).length
}

export function chatState(chat: StoredChat, { after, before }: { after?: number; before?: number }): ChatState {
  let messages: ChatMessage[]
  let hasOlder = false
  if (after !== undefined) {
    messages = chat.messages.filter((m) => m.id > after)
  } else {
    const pool = before !== undefined ? chat.messages.filter((m) => m.id < before) : chat.messages
    hasOlder = pool.length > PAGE
    messages = pool.slice(-PAGE)
  }
  return { conversation: chat.conversation, messages, has_older: hasOlder, unread: unreadCount(chat) }
}

export async function addCustomerMessage(
  userId: number,
  lang: Lang,
  input: { body: string; image: ChatMessage['image']; order: ChatMessage['order'] },
) {
  const chat = await loadChat(userId)
  if (!chat.conversation || chat.conversation.status !== 'open') {
    chat.conversation = { id: await nextId(), status: 'open', staff_last_read: 0, customer_last_read: 0 }
  }
  const message: ChatMessage = {
    id: await nextId(),
    conversation: chat.conversation.id,
    kind: 'text',
    event: '',
    sender: 'customer',
    sender_name: '',
    created_at: new Date().toISOString(),
    ...input,
  }
  chat.messages.push(message)
  chat.conversation.customer_last_read = message.id
  chat.replyDueAt ??= Date.now() + REPLY_AFTER_MS
  chat.replyLang = lang
  await saveChat(userId, chat)
  return message
}
