/** Reactive navigator.onLine (always true during SSR). */
export function useOnline() {
  const online = useState('online', () => true)
  if (import.meta.client) {
    onMounted(() => {
      online.value = navigator.onLine
      const update = () => (online.value = navigator.onLine)
      window.addEventListener('online', update)
      window.addEventListener('offline', update)
      onBeforeUnmount(() => {
        window.removeEventListener('online', update)
        window.removeEventListener('offline', update)
      })
    })
  }
  return online
}
