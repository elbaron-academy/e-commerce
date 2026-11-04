export interface Toast {
  id: number
  message: string
  tone: 'default' | 'success' | 'error'
}

let nextId = 1

export function useToast() {
  const toasts = useState<Toast[]>('toasts', () => [])
  function show(message: string, tone: Toast['tone'] = 'default', ms = 2600) {
    const id = nextId++
    toasts.value = [...toasts.value.slice(-2), { id, message, tone }]
    if (import.meta.client) setTimeout(() => dismiss(id), ms)
  }
  function dismiss(id: number) {
    toasts.value = toasts.value.filter((t) => t.id !== id)
  }
  return { toasts, show, dismiss }
}
