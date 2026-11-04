export default defineNuxtRouteMiddleware((to) => {
  const auth = useAuthStore()
  if (!auth.isLoggedIn) {
    return navigateTo({ path: useLocalePath()('/login'), query: { redirect: to.fullPath } })
  }
})
