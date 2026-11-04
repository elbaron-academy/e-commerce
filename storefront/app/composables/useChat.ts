import type { ChatConversationRef, ChatMessage, ChatState } from '#shared/types/api'

/** A message on screen: from the server, or one of ours still being sent. */
export interface ChatItem extends ChatMessage {
  local?: {
    key: string
    status: 'sending' | 'failed'
    file: File | null
    preview: string | null
    error: string
  }
}

interface Draft {
  body: string
  file?: File | null
  orderId?: number | null
  orderNumber?: string
}

/**
 * The customer's support chat. Loads the latest messages, polls for new ones,
 * sends with an optimistic bubble (retry on failure) and keeps read receipts.
 */
export function useChat() {
  const { $api } = useNuxtApp()
  const chatStore = useChatStore()

  const items = ref<ChatItem[]>([])
  const conversation = ref<ChatConversationRef | null>(null)
  const hasOlder = ref(false)
  const loading = ref(true)
  const loadFailed = ref(false)
  const loadingOlder = ref(false)
  let polling = false

  const serverItems = () => items.value.filter((m) => !m.local)
  const lastId = () => serverItems().reduce((max, m) => Math.max(max, m.id), 0)

  /** Adds messages we don't have yet. Returns the new ones. */
  function merge(incoming: ChatMessage[]): ChatMessage[] {
    const known = new Set(serverItems().map((m) => m.id))
    const fresh = incoming.filter((m) => !known.has(m.id))
    if (fresh.length) {
      const server = [...serverItems(), ...fresh].sort((a, b) => a.id - b.id)
      items.value = [...server, ...items.value.filter((m) => m.local)]
    }
    return fresh
  }

  function apply(state: ChatState) {
    conversation.value = state.conversation
    chatStore.unread = state.unread
  }

  async function load() {
    loading.value = true
    loadFailed.value = false
    try {
      const state = await $api<ChatState>('/support/chat/')
      items.value = [...state.messages, ...items.value.filter((m) => m.local)]
      hasOlder.value = state.has_older
      apply(state)
    } catch {
      loadFailed.value = true
    } finally {
      loading.value = false
    }
  }

  /** Fetches messages newer than the last one we have. */
  async function poll(): Promise<ChatMessage[]> {
    if (polling || loading.value || loadFailed.value) return []
    polling = true
    try {
      const state = await $api<ChatState>('/support/chat/', { query: { after: lastId() } })
      apply(state)
      return merge(state.messages)
    } catch {
      return []
    } finally {
      polling = false
    }
  }

  async function loadOlder() {
    const first = serverItems()[0]
    if (!first || loadingOlder.value) return
    loadingOlder.value = true
    try {
      const state = await $api<ChatState>('/support/chat/', { query: { before: first.id } })
      hasOlder.value = state.has_older
      merge(state.messages)
    } finally {
      loadingOlder.value = false
    }
  }

  async function deliver(item: ChatItem) {
    const local = item.local!
    local.status = 'sending'
    local.error = ''
    try {
      let body: FormData | Record<string, unknown>
      if (local.file) {
        body = new FormData()
        body.append('body', item.body)
        body.append('image', local.file)
        if (item.order) body.append('order', String(item.order.id))
      } else {
        body = { body: item.body, order: item.order?.id ?? null }
      }
      const message = await $api<ChatMessage>('/support/chat/messages/', { method: 'POST', body })
      items.value = items.value.filter((m) => m.local?.key !== local.key)
      merge([message])
      if (local.preview) URL.revokeObjectURL(local.preview)
      // A first message may have opened a new conversation.
      if (!conversation.value || conversation.value.status !== 'open' || conversation.value.id !== message.conversation) {
        await poll()
      }
    } catch (error) {
      const target = items.value.find((m) => m.local?.key === local.key)
      if (target?.local) {
        target.local.status = 'failed'
        const status = (error as { status?: number })?.status ?? (error as { response?: { status?: number } })?.response?.status
        // Show the server's reason for bad input (e.g. a photo that's too large); otherwise just "tap to retry".
        target.local.error = status && status < 500 && status !== 401 ? apiErrorMessage(error, '') : ''
      }
    }
  }

  function send(draft: Draft) {
    const body = draft.body.trim()
    if (!body && !draft.file) return
    const key = `local-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const item: ChatItem = {
      id: Number.MAX_SAFE_INTEGER,
      conversation: conversation.value?.id ?? 0,
      kind: 'text',
      event: '',
      sender: 'customer',
      sender_name: '',
      body,
      image: null,
      order: draft.orderId ? { id: draft.orderId, number: draft.orderNumber ?? '' } : null,
      created_at: new Date().toISOString(),
      local: { key, status: 'sending', file: draft.file ?? null, preview: draft.file ? URL.createObjectURL(draft.file) : null, error: '' },
    }
    items.value = [...items.value, item]
    const reactiveItem = items.value[items.value.length - 1]!
    void deliver(reactiveItem)
  }

  function retry(item: ChatItem) {
    if (item.local?.status === 'failed') void deliver(item)
  }

  function discard(item: ChatItem) {
    if (item.local?.preview) URL.revokeObjectURL(item.local.preview)
    items.value = items.value.filter((m) => m !== item)
  }

  /** Tells the server we've seen the support team's latest message. */
  async function markRead() {
    const latestStaff = [...serverItems()].reverse().find((m) => m.sender === 'staff' && m.kind === 'text')
    if (!latestStaff || !conversation.value || latestStaff.id <= conversation.value.customer_last_read) return
    conversation.value = { ...conversation.value, customer_last_read: latestStaff.id }
    chatStore.unread = 0
    try {
      const res = await $api<{ unread: number }>('/support/chat/read/', { method: 'POST', body: { message_id: latestStaff.id } })
      chatStore.unread = res.unread
    } catch {
      // Next poll tries again.
    }
  }

  /** ✓ sent, ✓✓ seen by the support team. */
  function receipt(item: ChatItem): 'sending' | 'failed' | 'sent' | 'seen' {
    if (item.local) return item.local.status
    const c = conversation.value
    if (!c || item.conversation !== c.id) return 'seen'
    return item.id <= c.staff_last_read ? 'seen' : 'sent'
  }

  const closed = computed(() => conversation.value?.status === 'closed')
  const empty = computed(() => !loading.value && !loadFailed.value && items.value.length === 0)

  return {
    items,
    conversation,
    hasOlder,
    loading,
    loadFailed,
    loadingOlder,
    closed,
    empty,
    load,
    poll,
    loadOlder,
    send,
    retry,
    discard,
    markRead,
    receipt,
  }
}
