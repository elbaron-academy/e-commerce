// Starts after 2 characters (BE-304).
export default defineEventHandler((event) => {
  const q = String(getQuery(event).q || '').trim()
  if (q.length < 2) return []
  return autocomplete(q, getLang(event))
})
