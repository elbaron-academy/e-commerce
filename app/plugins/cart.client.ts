// Loads the cart from localStorage once hydration has finished, so server and
// client render the same first frame. Then keeps it saved and in sync across tabs.
export default defineNuxtPlugin(() => {
  const cart = useCartStore()
  onNuxtReady(() => {
    cart.load()
    watch(() => [cart.lines, cart.coupon], () => cart.persist(), { deep: true })
    window.addEventListener('storage', (e) => {
      if (e.key === CART_STORAGE_KEY) cart.load()
    })
  })
})
