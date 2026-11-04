<script setup lang="ts">
withDefaults(
  defineProps<{
    subtotal: number
    total: number
    deliveryFee: number
    couponDiscount?: number
    savings?: number
    deliveryLabel?: string
  }>(),
  { couponDiscount: 0, savings: 0, deliveryLabel: '' },
)
const { t } = useI18n()
const { money } = useFormat()
</script>

<template>
  <dl class="space-y-2.5 text-sm">
    <div class="flex justify-between gap-4">
      <dt class="text-muted">{{ t('cart.subtotal') }}</dt>
      <dd class="font-semibold">{{ money(subtotal) }}</dd>
    </div>
    <div v-if="couponDiscount" class="flex justify-between gap-4 text-brand-700">
      <dt>{{ t('cart.coupon') }}</dt>
      <dd class="font-semibold">{{ money(-couponDiscount) }}</dd>
    </div>
    <div class="flex justify-between gap-4">
      <dt class="text-muted">{{ deliveryLabel || t('cart.delivery') }}</dt>
      <dd class="font-semibold" :class="!deliveryFee && 'text-brand-700'">{{ deliveryFee ? money(deliveryFee) : t('common.free') }}</dd>
    </div>
    <div class="flex justify-between gap-4 border-t border-line pt-3 text-base">
      <dt class="font-extrabold">{{ t('cart.total') }}</dt>
      <dd class="font-extrabold">{{ money(total) }}</dd>
    </div>
    <p v-if="savings" class="rounded-lg bg-accent-50 text-accent-700 text-xs font-bold px-2.5 py-1.5 text-center">
      🎉 {{ t('cart.savings') }} {{ money(savings) }}
    </p>
    <p class="text-xs text-muted">{{ t('cart.vatIncluded') }}</p>
  </dl>
</template>
