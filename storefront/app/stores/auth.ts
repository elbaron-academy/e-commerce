import { defineStore } from 'pinia'
import type { AuthTokens, User } from '#shared/types/api'

const cookieOptions = { maxAge: 60 * 60 * 24 * 30, sameSite: 'lax' as const }

export const useAuthStore = defineStore('auth', () => {
  const token = useCookie<string | null>('rk_token', cookieOptions)
  const refresh = useCookie<string | null>('rk_refresh', cookieOptions)
  const user = useCookie<User | null>('rk_user', cookieOptions)

  const isLoggedIn = computed(() => !!token.value)

  function setSession(tokens: AuthTokens) {
    token.value = tokens.access
    refresh.value = tokens.refresh
    user.value = tokens.user
  }

  function setUser(next: User) {
    user.value = next
  }

  function logout() {
    token.value = null
    refresh.value = null
    user.value = null
  }

  return { token, user, isLoggedIn, setSession, setUser, logout }
})
