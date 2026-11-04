// The mock API is for development and demos. Turn it off with NUXT_MOCK_API=false.
export default defineEventHandler((event) => {
  if (!event.path.startsWith('/api/v1')) return
  if (!useRuntimeConfig(event).mockApi) {
    throw createError({ statusCode: 404, statusMessage: 'Mock API is disabled' })
  }
})
