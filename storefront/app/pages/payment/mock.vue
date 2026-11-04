<script setup lang="ts">
import type { Order } from '#shared/types/api'

// Stand-in for the payment gateway's hosted page (FE-502). Removed once BE-504 is live.
definePageMeta({ middleware: 'auth', hideBottomNav: true })

const { t } = useI18n()
const { money } = useFormat()
const { $api } = useNuxtApp()
const route = useRoute()
const cart = useCartStore()
const localePath = useLocalePath()

useSeoMeta({ title: () => t('payment.title'), robots: 'noindex' })

const orderId = computed(() => Number(route.query.order))
const { data: order } = useApiFetch<Order>(() => `/orders/${orderId.value}/`)
const busy = ref(false)
const failed = ref(false)

async function confirm(result: 'success' | 'failed') {
  busy.value = true
  try {
    const updated = await $api<Order>('/payments/mock/confirm/', { method: 'POST', body: { order_id: orderId.value, result } })
    if (result === 'success') {
      cart.clear()
      await navigateTo({ path: localePath(`/orders/${updated.id}`), query: { paid: '1' } }, { replace: true })
    } else {
      failed.value = true
    }
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="max-w-md mx-auto pt-4 md:pt-10">
    <div class="card p-6 space-y-5">
      <div class="flex items-center gap-3">
        <span class="grid place-items-center size-11 rounded-xl bg-ink text-white"><AppIcon name="card" :size="22" /></span>
        <div>
          <h1 class="font-extrabold">{{ t('payment.title') }}</h1>
          <p class="text-xs text-muted">{{ order?.number }}</p>
        </div>
      </div>
      <p class="text-sm text-muted">{{ t('payment.hint') }}</p>
      <div class="rounded-2xl bg-canvas p-4 flex items-center justify-between">
        <span class="text-sm font-semibold">{{ t('payment.amount') }}</span>
        <span class="text-xl font-extrabold">{{ order ? money(order.total) : '…' }}</span>
      </div>
      <div class="grid grid-cols-3 gap-2" dir="ltr" aria-hidden="true">
        <input class="field col-span-3 font-mono" value="4242 4242 4242 4242" disabled>
        <input class="field font-mono" value="12/29" disabled>
        <input class="field font-mono" value="123" disabled>
      </div>

      <template v-if="!failed">
        <button type="button" class="btn-primary w-full h-12 text-base" :disabled="busy || !order" @click="confirm('success')">{{ t('payment.success') }}</button>
        <button type="button" class="btn-outline w-full" :disabled="busy || !order" @click="confirm('failed')">{{ t('payment.fail') }}</button>
      </template>
      <template v-else>
        <p class="rounded-xl bg-danger-50 text-danger text-sm font-bold p-3">{{ t('payment.failed') }}</p>
        <NuxtLinkLocale to="/cart" class="btn-primary w-full">{{ t('payment.backToCart') }}</NuxtLinkLocale>
      </template>
    </div>
  </div>
</template>
