import { defineStore } from 'pinia'

/** Unread support replies, for the badge on the chat buttons. */
export const useChatStore = defineStore('chat', () => {
  const unread = ref(0)

  async function refreshUnread() {
    const auth = useAuthStore()
    if (!auth.isLoggedIn) {
      unread.value = 0
      return
    }
    try {
      unread.value = (await useNuxtApp().$api<{ unread: number }>('/support/chat/unread/')).unread
    } catch {
      // Keep the last count on a network blip.
    }
  }

  return { unread, refreshUnread }
})
