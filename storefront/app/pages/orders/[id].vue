<script setup lang="ts">
import type { Order } from '#shared/types/api'

definePageMeta({ middleware: 'auth' })

const { t } = useI18n()
const { money, date, time, qty } = useFormat()
const route = useRoute()
const cart = useCartStore()
const toast = useToast()
const localePath = useLocalePath()

const id = computed(() => String(route.params.id))
const { data: order, refresh, error } = useApiFetch<Order>(() => `/orders/${id.value}/`)

useSeoMeta({ title: () => (order.value ? t('orders.number', { n: order.value.number }) : t('orders.title')), robots: 'noindex' })

const banner = computed(() => (route.query.paid ? t('orders.paid') : route.query.placed ? t('orders.placed') : ''))
const finished = computed(() => ['delivered', 'cancelled'].includes(order.value?.status ?? ''))

// Live tracking: poll while the order is moving. Sprint 6 adds push updates (MOB-603 for web).
let timer: ReturnType<typeof setInterval> | undefined
onMounted(() => {
  timer = setInterval(() => {
    if (!finished.value && document.visibilityState === 'visible') refresh()
  }, 20_000)
})
onBeforeUnmount(() => clearInterval(timer))

const paymentLabel = computed(() => (order.value ? t(`checkout.${order.value.payment_method}`) : ''))
const slotLabel = computed(() => {
  const s = order.value?.slot
  if (!s) return ''
  if (s.express) return t('checkout.express')
  return `${date(`${s.date}T12:00:00`, { weekday: 'long', day: 'numeric', month: 'short' })} · ${time(s.start)} – ${time(s.end)}`
})

function reorder() {
  if (!order.value) return
  cart.addFromOrder(order.value.items)
  toast.show(t('orders.reordered'), 'success')
  navigateTo(localePath('/cart'))
}
</script>

<template>
  <div class="max-w-4xl mx-auto">
    <EmptyState v-if="error" emoji="🧭" :title="t('error.notFound')">
      <NuxtLinkLocale to="/orders" class="btn-primary px-6">{{ t('orders.title') }}</NuxtLinkLocale>
    </EmptyState>

    <div v-else-if="!order" class="card h-64 animate-pulse" />

    <template v-else>
      <p v-if="banner" class="rounded-2xl bg-brand-600 text-white font-bold p-4 mb-4 flex items-center gap-3">
        <span class="grid place-items-center size-9 rounded-full bg-white/20"><AppIcon name="check" :size="20" :stroke="3" /></span>
        {{ banner }}
      </p>

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <NuxtLinkLocale to="/orders" class="grid place-items-center size-10 rounded-xl hover:bg-white" :aria-label="t('common.back')">
          <AppIcon name="arrow-start" :size="20" />
        </NuxtLinkLocale>
        <div>
          <h1 class="text-xl font-extrabold">{{ t('orders.number', { n: order.number }) }}</h1>
          <p class="text-xs text-muted">{{ date(order.created_at, { day: 'numeric', month: 'long', hour: 'numeric', minute: '2-digit' }) }}</p>
        </div>
        <OrderStatusBadge class="ms-auto" :status="order.status" :method="order.method" />
      </div>

      <div class="grid md:grid-cols-[1fr_340px] gap-4 items-start">
        <div class="space-y-4">
          <section v-if="order.status !== 'cancelled' && order.status !== 'pending_payment'" class="card p-4">
            <h2 class="font-extrabold mb-4">{{ t('orders.tracking') }}</h2>
            <OrderTimeline :order="order" />
          </section>

          <section class="card p-4">
            <h2 class="font-extrabold mb-3">{{ t('orders.details') }} <span class="text-sm text-muted font-semibold">({{ t('orders.items', { n: order.items.length }) }})</span></h2>
            <ul class="divide-y divide-line">
              <li v-for="item in order.items" :key="item.sku" class="py-2.5 flex items-center gap-3">
                <ProductImage size="xs" :emoji="item.emoji" :color="item.color" :image="item.image" :alt="item.name" class="size-12 rounded-xl" />
                <div class="flex-1 min-w-0 text-sm">
                  <p class="font-semibold truncate">{{ item.name }}</p>
                  <p class="text-xs text-muted">{{ item.sold_by_weight ? qty(item.qty, true) : `${item.variant_label} × ${qty(item.qty, false)}` }}</p>
                </div>
                <span class="font-bold text-sm">{{ money(item.line_total) }}</span>
              </li>
            </ul>
          </section>
        </div>

        <aside class="space-y-4">
          <section class="card p-4 space-y-3 text-sm">
            <div class="flex gap-3">
              <AppIcon :name="order.method === 'pickup' ? 'store' : 'map-pin'" :size="20" class="text-brand-700 shrink-0" />
              <div>
                <p class="text-xs text-muted">{{ order.method === 'pickup' ? t('orders.pickupFrom') : t('orders.deliverTo') }}</p>
                <p class="font-semibold">
                  {{ order.address ? [order.address.street, order.address.building, order.address.area, order.address.zone_name].filter(Boolean).join('، ') : t('checkout.pickup') }}
                </p>
              </div>
            </div>
            <div class="flex gap-3">
              <AppIcon name="clock" :size="20" class="text-brand-700 shrink-0" />
              <div>
                <p class="text-xs text-muted">{{ t('orders.slot') }}</p>
                <p class="font-semibold">{{ slotLabel }}</p>
              </div>
            </div>
            <div class="flex gap-3">
              <AppIcon :name="order.payment_method === 'cod' ? 'cash' : 'card'" :size="20" class="text-brand-700 shrink-0" />
              <div>
                <p class="text-xs text-muted">{{ t('orders.paymentMethod') }}</p>
                <p class="font-semibold">{{ paymentLabel }}</p>
              </div>
            </div>
          </section>

          <section class="card p-4">
            <OrderSummary :subtotal="order.subtotal" :total="order.total" :delivery-fee="order.delivery_fee" :coupon-discount="order.coupon_discount" />
          </section>

          <button type="button" class="btn-primary w-full" @click="reorder">
            <AppIcon name="refresh" :size="18" /> {{ t('orders.reorder') }}
          </button>
        </aside>
      </div>
    </template>
  </div>
</template>
