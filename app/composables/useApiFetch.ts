import type { UseFetchOptions } from 'nuxt/app'

/**
 * useFetch bound to the Rocket API. Adds the current language to the query so
 * each language gets its own cache entry and refetches when it changes.
 */
export function useApiFetch<T>(url: string | (() => string), options: UseFetchOptions<T> = {}) {
  const { locale } = useI18n()
  const query = computed(() => ({ ...(toValue(options.query as MaybeRefOrGetter<Record<string, unknown>>) ?? {}), lang: locale.value }))
  return useFetch(url, {
    ...options,
    query,
    $fetch: useNuxtApp().$api as typeof $fetch,
  })
}

export function useCategories() {
  return useApiFetch<import('#shared/types/api').CategoryNode[]>('/categories/', { key: 'categories', dedupe: 'defer' })
}

/** Reads the message from a DRF or Nitro error response. */
export function apiErrorMessage(error: unknown, fallback: string): string {
  const data = (error as { data?: Record<string, any> })?.data
  return data?.detail ?? data?.data?.detail ?? fallback
}
