// $api: the HTTP client for the Rocket backend (mock or Django REST).
// Sends the language as ?lang= (cache-friendly) and the JWT access token.
export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig()
  const auth = useAuthStore()

  const baseURL = import.meta.server && config.apiBaseServer ? config.apiBaseServer : config.public.apiBase

  const api = $fetch.create({
    baseURL,
    onRequest({ options }) {
      const locale = nuxtApp.$i18n.locale.value
      const query = (options.query ?? {}) as Record<string, unknown>
      options.query = { lang: locale, ...query }
      const headers = new Headers(options.headers as HeadersInit | undefined)
      headers.set('Accept-Language', locale)
      if (auth.token) headers.set('Authorization', `Bearer ${auth.token}`)
      options.headers = headers
    },
    async onResponseError({ response }) {
      // TODO(BE-101): try the refresh token before signing out.
      if (response.status === 401 && auth.token) {
        auth.logout()
        await nuxtApp.runWithContext(() => navigateTo(useLocalePath()('/login')))
      }
    },
  })

  return { provide: { api } }
})
