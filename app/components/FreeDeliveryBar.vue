<script setup lang="ts">
const props = defineProps<{ subtotal: number; threshold: number }>()
const { t } = useI18n()
const { money } = useFormat()
const remaining = computed(() => Math.max(0, props.threshold - props.subtotal))
const percent = computed(() => Math.min(100, (props.subtotal / props.threshold) * 100))
</script>

<template>
  <div class="rounded-2xl bg-brand-50 border border-brand-100 p-3">
    <p class="text-sm font-semibold flex items-center gap-2 text-brand-800">
      <AppIcon name="truck" :size="18" />
      {{ remaining > 0 ? t('cart.freeDeliveryLeft', { amount: money(remaining) }) : t('cart.freeDeliveryReached') }}
    </p>
    <div class="mt-2 h-2 rounded-full bg-brand-100 overflow-hidden" role="progressbar" :aria-valuenow="Math.round(percent)" aria-valuemin="0" aria-valuemax="100">
      <div class="h-full bg-brand-500 rounded-full transition-all duration-500" :style="{ width: `${percent}%` }" />
    </div>
  </div>
</template>
