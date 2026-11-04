<script setup lang="ts">
import type { Address, DeliveryInfo, DeliveryMethod, OrderCreateResponse, PaymentMethod, Quote, SlotDay } from '#shared/types/api'

definePageMeta({ middleware: 'auth', hideBottomNav: true })

const { t } = useI18n()
const { money, date, time } = useFormat()
const { $api } = useNuxtApp()
const cart = useCartStore()
const localePath = useLocalePath()

useSeoMeta({ title: () => t('checkout.title'), robots: 'noindex' })

const { data: info } = useApiFetch<DeliveryInfo>('/delivery/info/', { key: 'delivery-info' })
const { data: slotDays } = useApiFetch<SlotDay[]>('/delivery/slots/', { key: 'delivery-slots' })
const { data: addresses, refresh: refreshAddresses } = useApiFetch<Address[]>('/addresses/', { key: 'addresses' })

const method = ref<DeliveryMethod>('delivery')
const addressId = ref<number | null>(null)
const showAddressForm = ref(false)
const dayIndex = ref(0)
const slotId = ref<string | null>(null)
const payment = ref<PaymentMethod>('cod')
const notes = ref('')
const quote = ref<Quote | null>(null)
const placing = ref(false)
const error = ref('')

watch(addresses, (list) => {
  if (!list) return
  if (!list.length) showAddressForm.value = true
  if (!list.some((a) => a.id === addressId.value)) addressId.value = (list.find((a) => a.is_default) ?? list[0])?.id ?? null
}, { immediate: true })

const address = computed(() => addresses.value?.find((a) => a.id === addressId.value) ?? null)
const days = computed(() =>
  (slotDays.value ?? [])
    .map((d) => ({ ...d, slots: d.slots.filter((s) => method.value === 'delivery' || !s.express) }))
    .filter((d) => d.slots.some((s) => s.available)),
)
const daySlots = computed(() => days.value[dayIndex.value]?.slots ?? [])

// Keep a valid slot selected when the method or available days change.
watch(days, (list) => {
  const all = list.flatMap((d) => d.slots)
  if (!all.some((s) => s.id === slotId.value && s.available)) {
    slotId.value = all.find((s) => s.available)?.id ?? null
    dayIndex.value = Math.max(0, list.findIndex((d) => d.slots.some((s) => s.id === slotId.value)))
  }
}, { immediate: true })

const cairoToday = new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Cairo' }).format(new Date())
function dayLabel(day: string) {
  const diff = Math.round((Date.parse(day) - Date.parse(cairoToday)) / 86_400_000)
  if (diff === 0) return t('checkout.today')
  if (diff === 1) return t('checkout.tomorrow')
  return date(`${day}T12:00:00`, { weekday: 'long', day: 'numeric', month: 'short' })
}

const zone = computed(() => (method.value === 'delivery' ? address.value?.zone ?? null : null))

async function refreshQuote() {
  if (!cart.lines.length) return
  try {
    quote.value = await $api<Quote>('/cart/quote/', {
      method: 'POST',
      body: { items: cart.lines.map((l) => ({ sku: l.sku, qty: l.qty })), coupon: cart.coupon, zone: zone.value, method: method.value },
    })
  } catch {}
}
watch([() => cart.loaded, method, zone, () => cart.lines.length], ([loaded]) => loaded && refreshQuote(), { immediate: true })
watch(() => quote.value?.cod_available, (ok) => {
  if (ok === false && payment.value === 'cod') payment.value = 'card'
})

function onAddressSaved(saved: Address) {
  showAddressForm.value = false
  addressId.value = saved.id
  refreshAddresses()
}

const payments = computed(() => [
  { id: 'cod' as const, icon: 'cash' as const, title: t('checkout.cod'), hint: quote.value && !quote.value.cod_available ? t('checkout.codUnavailable', { amount: money(quote.value.cod_limit) }) : '', disabled: quote.value ? !quote.value.cod_available : false },
  { id: 'card' as const, icon: 'card' as const, title: t('checkout.card'), hint: t('checkout.cardHint'), disabled: false },
  { id: 'wallet' as const, icon: 'wallet' as const, title: t('checkout.wallet'), hint: t('checkout.walletHint'), disabled: false },
])

const submitLabel = computed(() => (payment.value === 'cod' ? t('checkout.placeOrder') : t('checkout.payNow', { amount: money(quote.value?.total ?? 0) })))

async function placeOrder() {
  error.value = ''
  if (method.value === 'delivery' && !address.value) return (error.value = t('checkout.chooseAddress'))
  if (!slotId.value) return (error.value = t('checkout.chooseSlot'))
  placing.value = true
  try {
    const res = await $api<OrderCreateResponse>('/orders/', {
      method: 'POST',
      body: {
        items: cart.lines.map((l) => ({ sku: l.sku, qty: l.qty })),
        coupon: cart.coupon,
        method: method.value,
        address_id: method.value === 'delivery' ? addressId.value : null,
        slot_id: slotId.value,
        payment_method: payment.value,
        notes: notes.value,
      },
    })
    if (res.payment_url) {
      // Real gateways return an absolute URL; the mock returns an in-app path.
      if (/^https?:\/\//.test(res.payment_url)) return navigateTo(res.payment_url, { external: true })
      const url = new URL(res.payment_url, window.location.origin)
      return navigateTo({ path: localePath(url.pathname), query: Object.fromEntries(url.searchParams) })
    }
    cart.clear()
    await navigateTo({ path: localePath(`/orders/${res.order.id}`), query: { placed: '1' } }, { replace: true })
  } catch (e) {
    error.value = apiErrorMessage(e, t('common.error'))
    refreshQuote()
  } finally {
    placing.value = false
  }
}
</script>

<template>
  <div class="pb-24 lg:pb-0">
    <div class="flex items-center gap-2 mb-4">
      <NuxtLinkLocale to="/cart" class="grid place-items-center size-10 rounded-xl hover:bg-white" :aria-label="t('common.back')">
        <AppIcon name="arrow-start" :size="20" />
      </NuxtLinkLocale>
      <h1 class="text-2xl font-extrabold">{{ t('checkout.title') }}</h1>
    </div>

    <EmptyState v-if="cart.loaded && !cart.lines.length" emoji="🛒" :title="t('checkout.emptyCart')">
      <NuxtLinkLocale to="/" class="btn-primary px-6">{{ t('common.startShopping') }}</NuxtLinkLocale>
    </EmptyState>

    <div v-else class="grid lg:grid-cols-[1fr_360px] gap-5 items-start">
      <div class="space-y-4">
        <!-- 1. Delivery or pickup (US-22) -->
        <section class="card p-4">
          <h2 class="font-extrabold mb-3">{{ t('checkout.method') }}</h2>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="m in (['delivery', 'pickup'] as const)"
              :key="m"
              type="button"
              class="rounded-xl border-2 p-3 flex items-center gap-2.5 text-sm font-bold text-start transition"
              :class="method === m ? 'border-brand-600 bg-brand-50' : 'border-line'"
              :aria-pressed="method === m"
              @click="method = m"
            >
              <AppIcon :name="m === 'delivery' ? 'truck' : 'store'" :size="20" class="text-brand-700" />
              {{ t(`checkout.${m}`) }}
            </button>
          </div>
          <p v-if="method === 'pickup' && info" class="mt-3 text-sm rounded-xl bg-canvas p-3">
            <span class="font-bold block">{{ info.pickup.name }}</span>
            <span class="text-muted">{{ info.pickup.address }} · {{ info.pickup.hours }}</span>
          </p>
        </section>

        <!-- 2. Address (US-34) -->
        <section v-if="method === 'delivery'" class="card p-4">
          <h2 class="font-extrabold mb-3">{{ t('checkout.address') }}</h2>
          <div v-if="addresses?.length && !showAddressForm" class="space-y-2">
            <label
              v-for="a in addresses"
              :key="a.id"
              class="flex gap-3 rounded-xl border-2 p-3 cursor-pointer transition"
              :class="addressId === a.id ? 'border-brand-600 bg-brand-50' : 'border-line'"
            >
              <input v-model="addressId" type="radio" name="address" :value="a.id" class="mt-1 accent-brand-600">
              <span class="text-sm min-w-0">
                <span class="font-bold block">{{ a.label || a.area }} <span v-if="a.is_default" class="text-xs text-brand-700">· {{ t('address.default') }}</span></span>
                <span class="text-muted block truncate">{{ [a.street, a.building, a.area, a.zone_name].filter(Boolean).join('، ') }}</span>
              </span>
            </label>
            <button type="button" class="btn-ghost px-2" @click="showAddressForm = true">
              <AppIcon name="plus" :size="18" /> {{ t('checkout.addAddress') }}
            </button>
          </div>
          <template v-else>
            <p v-if="!addresses?.length" class="text-sm text-muted mb-3">{{ t('checkout.noAddresses') }}</p>
            <AddressForm @saved="onAddressSaved" @cancel="showAddressForm = false" />
          </template>
        </section>

        <!-- 3. Time slot -->
        <section class="card p-4">
          <h2 class="font-extrabold mb-3">{{ method === 'delivery' ? t('checkout.time') : t('checkout.pickupTime') }}</h2>
          <div class="-mx-4 px-4 flex gap-2 overflow-x-auto no-scrollbar">
            <button
              v-for="(d, i) in days"
              :key="d.date"
              type="button"
              class="chip"
              :class="dayIndex === i && 'chip-active'"
              @click="dayIndex = i"
            >
              {{ dayLabel(d.date) }}
            </button>
          </div>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 mt-3">
            <button
              v-for="s in daySlots"
              :key="s.id"
              type="button"
              :disabled="!s.available"
              class="rounded-xl border-2 px-3 py-2.5 text-sm font-bold transition disabled:opacity-40 disabled:line-through"
              :class="[slotId === s.id ? 'border-brand-600 bg-brand-50' : 'border-line', s.express && 'col-span-2 sm:col-span-3 flex items-center gap-2']"
              :aria-pressed="slotId === s.id"
              @click="slotId = s.id"
            >
              <template v-if="s.express">
                <AppIcon name="zap" :size="18" class="text-accent-500" /> {{ t('checkout.express') }}
              </template>
              <span v-else dir="auto">{{ time(s.start) }} – {{ time(s.end) }}</span>
            </button>
          </div>
        </section>

        <!-- 4. Payment (US-23) -->
        <section class="card p-4">
          <h2 class="font-extrabold mb-3">{{ t('checkout.payment') }}</h2>
          <div class="space-y-2">
            <label
              v-for="p in payments"
              :key="p.id"
              class="flex items-center gap-3 rounded-xl border-2 p-3 transition"
              :class="[payment === p.id ? 'border-brand-600 bg-brand-50' : 'border-line', p.disabled ? 'opacity-50' : 'cursor-pointer']"
            >
              <input v-model="payment" type="radio" name="payment" :value="p.id" :disabled="p.disabled" class="accent-brand-600">
              <AppIcon :name="p.icon" :size="22" class="text-brand-700" />
              <span class="text-sm">
                <span class="font-bold block">{{ p.title }}</span>
                <span v-if="p.hint" class="text-xs text-muted">{{ p.hint }}</span>
              </span>
            </label>
          </div>
          <label class="block mt-4">
            <span class="label">{{ t('checkout.notes') }} <span class="text-muted font-normal">({{ t('common.optional') }})</span></span>
            <textarea v-model="notes" rows="2" maxlength="300" class="field h-auto py-2.5" :placeholder="t('checkout.notesPlaceholder')" />
          </label>
        </section>
      </div>

      <!-- Summary -->
      <aside class="card p-4 space-y-4 lg:sticky lg:top-32">
        <h2 class="font-extrabold">{{ t('cart.summary') }}</h2>
        <div class="flex -space-x-2 rtl:space-x-reverse">
          <ProductImage
            v-for="line in cart.lines.slice(0, 6)"
            :key="line.sku"
            size="xs"
            :emoji="line.emoji"
            :color="line.color"
            :image="line.image"
            :alt="line.name"
            class="size-11 rounded-full ring-2 ring-white"
          />
          <span v-if="cart.lines.length > 6" class="size-11 rounded-full ring-2 ring-white bg-canvas grid place-items-center text-xs font-bold">+{{ cart.lines.length - 6 }}</span>
        </div>
        <OrderSummary
          v-if="quote"
          :subtotal="quote.subtotal"
          :total="quote.total"
          :delivery-fee="quote.delivery_fee"
          :coupon-discount="quote.coupon_discount"
          :savings="quote.savings"
        />
        <div v-else class="h-32 rounded-xl bg-canvas animate-pulse" />
        <p v-if="quote && !quote.can_checkout" class="text-xs font-bold text-amber-700">{{ quote.warnings[0]?.message }}</p>
        <p v-if="error" class="rounded-xl bg-danger-50 text-danger text-sm font-bold p-3">{{ error }}</p>
        <button type="button" class="btn-primary w-full h-12 text-base hidden lg:flex" :disabled="placing || !quote?.can_checkout" @click="placeOrder">
          {{ placing ? t('checkout.placing') : submitLabel }}
        </button>
      </aside>
    </div>

    <div v-if="cart.lines.length" class="lg:hidden fixed inset-x-0 bottom-0 z-20 bg-white border-t border-line p-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))]">
      <p v-if="error" class="text-danger text-xs font-bold mb-2">{{ error }}</p>
      <button type="button" class="btn-primary w-full h-12 text-base" :disabled="placing || !quote?.can_checkout" @click="placeOrder">
        {{ placing ? t('checkout.placing') : submitLabel }}
      </button>
    </div>
  </div>
</template>
