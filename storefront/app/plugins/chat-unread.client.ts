// Checks for unread support replies every minute while the tab is visible.
// The chat page keeps the count itself while it's open.
export default defineNuxtPlugin(() => {
  const chat = useChatStore()
  const auth = useAuthStore()
  const router = useRouter()

  const onChatPage = () => /^\/(en\/)?chat\/?$/.test(router.currentRoute.value.path)
  const check = () => {
    if (document.visibilityState === 'visible' && navigator.onLine && !onChatPage()) chat.refreshUnread()
  }

  onNuxtReady(() => {
    check()
    setInterval(check, 60_000)
    document.addEventListener('visibilitychange', check)
    watch(() => auth.isLoggedIn, check)
  })
})
