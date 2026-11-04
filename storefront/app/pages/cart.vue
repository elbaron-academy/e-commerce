<script setup lang="ts">
import type { Quote } from '#shared/types/api'
import type { CartLine } from '~/stores/cart'

const { t } = useI18n()
const { money, qty } = useFormat()
const { $api } = useNuxtApp()
const cart = useCartStore()
const auth = useAuthStore()
const online = useOnline()
const toast = useToast()
const localePath = useLocalePath()

useSeoMeta({ title: () => t('cart.title'), robots: 'noindex' })

// The cart lives on the device; the server prices it (stock, sales, coupon, delivery).
const quote = ref<Quote | null>(null)
const couponInput = ref('')
const couponMessage = ref<{ text: string; ok: boolean } | null>(null)
let timer: ReturnType<typeof setTimeout> | undefined

const signature = computed(() => `${cart.lines.map((l) => `${l.sku}:${l.qty}`).join('|')}#${cart.coupon ?? ''}`)

async function refreshQuote() {
  if (!cart.lines.length) {
    quote.value = null
    return
  }
  try {
    const res = await $api<Quote>('/cart/quote/', {
      method: 'POST',
      body: { items: cart.lines.map((l) => ({ sku: l.sku, qty: l.qty, expected_price: l.price })), coupon: cart.coupon },
    })
    quote.value = res
    if (res.coupon) {
      couponMessage.value = { text: res.coupon.message, ok: res.coupon.valid }
      if (!res.coupon.valid) cart.coupon = null
    }
    cart.syncFromQuote(res)
  } catch {
    // Offline: keep showing the local estimate.
  }
}

watch([() => cart.loaded, signature], ([loaded]) => {
  if (!loaded) return
  clearTimeout(timer)
  timer = setTimeout(refreshQuote, 250)
}, { immediate: true })
watch(online, (isOnline) => isOnline && refreshQuote())

const quoteLine = (sku: string) => quote.value?.lines.find((l) => l.sku === sku)
const lineTotal = (line: CartLine) => quoteLine(line.sku)?.line_total ?? roundMoney(line.price * line.qty)
const unavailable = computed(() => new Set(quote.value?.lines.filter((l) => !l.available).map((l) => l.sku) ?? []))
const subtotal = computed(() => quote.value?.subtotal ?? cart.estimate)
const threshold = computed(() => quote.value?.free_delivery_threshold ?? 500)
const total = computed(() => quote.value?.total ?? subtotal.value)
const warnings = computed(() => quote.value?.warnings.filter((w) => w.code !== 'min_order') ?? [])
const minOrderWarning = computed(() => quote.value?.warnings.find((w) => w.code === 'min_order')?.message)
const canCheckout = computed(() => online.value && !!quote.value?.can_checkout)
const checkoutLabel = computed(() => (auth.isLoggedIn ? t('cart.checkout') : t('cart.loginToCheckout')))

function inc(sku: string) {
  if (!cart.increment(sku)) toast.show(t('product.maxReached'))
}
function removeUnavailable() {
  unavailable.value.forEach((sku) => cart.remove(sku))
}
function applyCoupon() {
  const code = couponInput.value.trim().toUpperCase()
  if (!code) return
  couponMessage.value = null
  cart.coupon = code
}
function removeCoupon() {
  cart.coupon = null
  couponMessage.value = null
  couponInput.value = ''
}
function checkout() {
  if (auth.isLoggedIn) navigateTo(localePath('/checkout'))
  else navigateTo({ path: localePath('/login'), query: { redirect: localePath('/checkout') } })
}
</script>

<template>
  <div class="pb-20 lg:pb-0">
    <h1 class="text-2xl font-extrabold mb-4">
      {{ t('cart.title') }}
      <span v-if="cart.count" class="text-base text-muted font-semibold">({{ t('cart.items', { n: cart.count }) }})</span>
    </h1>

    <div v-if="!cart.loaded" class="card h-64 animate-pulse" />

    <EmptyState v-else-if="!cart.lines.length" emoji="🛒" :title="t('cart.empty')" :text="t('cart.emptyHint')">
      <NuxtLinkLocale to="/" class="btn-primary px-6">{{ t('common.startShopping') }}</NuxtLinkLocale>
    </EmptyState>

    <div v-else class="grid lg:grid-cols-[1fr_360px] gap-5 items-start">
      <div class="space-y-3">
        <FreeDeliveryBar :subtotal="subtotal" :threshold="threshold" />

        <p v-if="!online" class="rounded-xl bg-ink text-white text-sm font-semibold p-3 flex gap-2">
          <AppIcon name="wifi-off" :size="18" /> {{ t('cart.offlineEstimate') }}
        </p>
        <div v-for="w in warnings" :key="w.code" class="rounded-xl bg-amber-50 border border-amber-200 text-amber-900 text-sm font-semibold p-3 flex flex-wrap items-center gap-2">
          <AppIcon name="alert" :size="18" /> <span class="flex-1">{{ w.message }}</span>
          <button v-if="w.code === 'unavailable'" type="button" class="underline font-bold" @click="removeUnavailable">{{ t('cart.removeUnavailable') }}</button>
        </div>

        <ul class="card divide-y divide-line">
          <li v-for="line in cart.lines" :key="line.sku" class="p-3 flex gap-3" :class="unavailable.has(line.sku) && 'bg-danger-50/40'">
            <NuxtLinkLocale :to="`/product/${line.slug}`" class="shrink-0" tabindex="-1">
              <ProductImage size="sm" :image="line.image" :emoji="line.emoji" :color="line.color" :alt="line.name" class="size-20 rounded-xl" />
            </NuxtLinkLocale>
            <div class="flex-1 min-w-0 flex flex-col">
              <div class="flex items-start gap-2">
                <div class="min-w-0 flex-1">
                  <NuxtLinkLocale :to="`/product/${line.slug}`" class="font-semibold text-sm leading-snug line-clamp-2">{{ line.name }}</NuxtLinkLocale>
                  <p class="text-xs text-muted mt-0.5">{{ line.variant_label }} · {{ money(line.price) }}</p>
                </div>
                <button type="button" class="text-muted hover:text-danger p-1 -m-1" :aria-label="t('product.remove')" @click="cart.remove(line.sku)">
                  <AppIcon name="x" :size="18" />
                </button>
              </div>
              <p v-if="unavailable.has(line.sku)" class="text-xs font-bold text-danger mt-1">{{ t('cart.unavailable') }}</p>
              <p v-else-if="quoteLine(line.sku)?.price_changed" class="text-xs font-bold text-amber-700 mt-1">{{ t('cart.priceUpdated') }}</p>
              <div class="mt-auto pt-2 flex items-center justify-between gap-3">
                <div v-if="!unavailable.has(line.sku)" class="w-32">
                  <QtyStepper
                    size="sm"
                    :label="qty(line.qty, line.sold_by_weight)"
                    :at-min="line.qty <= line.min"
                    :at-max="line.qty + line.step > line.max + 1e-9"
                    @inc="inc(line.sku)"
                    @dec="cart.decrement(line.sku)"
                  />
                </div>
                <div class="text-end ms-auto">
                  <p class="font-extrabold text-sm">{{ money(lineTotal(line)) }}</p>
                  <s v-if="line.original_price > line.price" class="text-xs text-muted">{{ money(line.original_price * line.qty) }}</s>
                </div>
              </div>
            </div>
          </li>
        </ul>

        <button type="button" class="btn-ghost text-danger hover:bg-danger-50" @click="cart.clear()">
          <AppIcon name="trash" :size="16" /> {{ t('cart.clear') }}
        </button>
      </div>

      <aside class="card p-4 space-y-4 lg:sticky lg:top-32">
        <h2 class="font-extrabold">{{ t('cart.summary') }}</h2>

        <div v-if="cart.coupon && couponMessage?.ok" class="flex items-center gap-2 rounded-xl bg-brand-50 border border-brand-200 px-3 h-11 text-sm">
          <AppIcon name="tag" :size="18" class="text-brand-700" />
          <span class="font-extrabold" dir="ltr">{{ cart.coupon }}</span>
          <span class="text-xs text-brand-700 truncate">{{ couponMessage.text }}</span>
          <button type="button" class="ms-auto p-1" :aria-label="t('cart.removeCoupon')" @click="removeCoupon"><AppIcon name="x" :size="16" /></button>
        </div>
        <form v-else class="flex gap-2" @submit.prevent="applyCoupon">
          <input v-model="couponInput" class="field uppercase" :placeholder="t('cart.couponPlaceholder')" :aria-label="t('cart.coupon')" autocapitalize="characters" autocomplete="off">
          <button type="submit" class="btn-outline shrink-0" :disabled="!couponInput.trim() || !online">{{ t('cart.apply') }}</button>
        </form>
        <p v-if="couponMessage && !couponMessage.ok" class="text-xs font-bold text-danger -mt-2">{{ couponMessage.text }}</p>

        <OrderSummary
          :subtotal="subtotal"
          :total="total"
          :delivery-fee="quote?.delivery_fee ?? 0"
          :coupon-discount="quote?.coupon_discount ?? 0"
          :savings="quote?.savings ?? 0"
          :delivery-label="t('cart.deliveryFrom')"
        />
        <p v-if="minOrderWarning" class="text-xs font-bold text-amber-700">{{ minOrderWarning }}</p>

        <button type="button" class="btn-primary w-full h-12 text-base hidden lg:flex" :disabled="!canCheckout" @click="checkout">
          {{ checkoutLabel }}
        </button>
      </aside>
    </div>

    <div v-if="cart.lines.length" class="lg:hidden fixed inset-x-0 z-20 bottom-[calc(4rem+env(safe-area-inset-bottom))] md:bottom-0 bg-white border-t border-line p-3">
      <button type="button" class="btn-primary w-full h-12 text-base !justify-between px-5" :disabled="!canCheckout" @click="checkout">
        <span>{{ checkoutLabel }}</span>
        <span>{{ money(total) }}</span>
      </button>
    </div>
  </div>
</template>
