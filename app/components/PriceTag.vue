<script setup lang="ts">
withDefaults(defineProps<{ price: number; salePrice?: number | null; size?: 'md' | 'lg' }>(), { salePrice: null, size: 'md' })
const { money } = useFormat()
</script>

<template>
  <div class="flex items-baseline flex-wrap gap-x-2 gap-y-0.5">
    <span class="font-extrabold" :class="[salePrice ? 'text-accent-600' : 'text-ink', size === 'lg' ? 'text-2xl' : 'text-[15px]']">
      {{ money(salePrice ?? price) }}
    </span>
    <s v-if="salePrice" class="text-muted" :class="size === 'lg' ? 'text-base' : 'text-xs'">{{ money(price) }}</s>
  </div>
</template>
