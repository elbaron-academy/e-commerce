<script setup lang="ts">
import type { DeliveryMethod, OrderStatus } from '#shared/types/api'

defineProps<{ status: OrderStatus; method: DeliveryMethod }>()
const { label, tone } = useOrderStatus()
</script>

<template>
  <span class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-bold whitespace-nowrap" :class="tone(status)">
    {{ label(status, method) }}
  </span>
</template>
