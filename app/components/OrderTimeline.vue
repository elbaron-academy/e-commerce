<script setup lang="ts">
import type { Order } from '#shared/types/api'

defineProps<{ order: Order }>()
const { label } = useOrderStatus()
const { date } = useFormat()
</script>

<template>
  <ol>
    <li v-for="(step, i) in order.timeline" :key="step.status" class="relative flex gap-3 pb-6 last:pb-0">
      <span
        v-if="i < order.timeline.length - 1"
        class="absolute start-[11px] top-6 bottom-0 w-0.5"
        :class="order.timeline[i + 1]?.done ? 'bg-brand-500' : 'bg-line'"
      />
      <span
        class="relative z-10 size-6 rounded-full grid place-items-center shrink-0"
        :class="step.done ? 'bg-brand-600 text-white' : 'bg-white border-2 border-line'"
      >
        <AppIcon v-if="step.done" name="check" :size="14" :stroke="3" />
      </span>
      <div class="-mt-0.5">
        <p class="text-sm font-bold" :class="!step.done && 'text-muted font-semibold'">{{ label(step.status, order.method) }}</p>
        <p v-if="step.at" class="text-xs text-muted">{{ date(step.at, { hour: 'numeric', minute: '2-digit' }) }}</p>
      </div>
    </li>
  </ol>
</template>
