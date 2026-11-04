const KEY = 'rk_recent_searches'

export function useRecentSearches() {
  const items = useState<string[]>('recent-searches', () => [])
  const read = () => {
    try {
      items.value = JSON.parse(localStorage.getItem(KEY) || '[]')
    } catch {
      items.value = []
    }
  }
  const write = () => {
    try {
      localStorage.setItem(KEY, JSON.stringify(items.value))
    } catch {}
  }
  function add(q: string) {
    const term = q.trim()
    if (term.length < 2) return
    read()
    items.value = [term, ...items.value.filter((x) => x !== term)].slice(0, 8)
    write()
  }
  function clear() {
    items.value = []
    write()
  }
  return { items, read, add, clear }
}
