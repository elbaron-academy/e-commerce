<script setup lang="ts">
withDefaults(defineProps<{ label: string; atMin?: boolean; atMax?: boolean; size?: 'sm' | 'md' | 'lg' }>(), { size: 'md' })
const emit = defineEmits<{ inc: []; dec: [] }>()
const { t } = useI18n()
const heights = { sm: 'h-9', md: 'h-10', lg: 'h-12' }
</script>

<template>
  <div class="flex items-center justify-between rounded-xl bg-brand-50 border border-brand-200 text-brand-800 w-full" :class="heights[size]">
    <button
      type="button"
      class="grid place-items-center h-full aspect-square rounded-xl hover:bg-brand-100 active:scale-95 transition"
      :aria-label="atMin ? t('product.remove') : t('product.decrease')"
      @click="emit('dec')"
    >
      <AppIcon :name="atMin ? 'trash' : 'minus'" :size="18" :stroke="2.4" />
    </button>
    <span class="font-extrabold text-sm tabular-nums" aria-live="polite">{{ label }}</span>
    <button
      type="button"
      class="grid place-items-center h-full aspect-square rounded-xl bg-brand-600 text-white hover:bg-brand-700 active:scale-95 transition disabled:opacity-40"
      :disabled="atMax"
      :aria-label="t('product.increase')"
      @click="emit('inc')"
    >
      <AppIcon name="plus" :size="18" :stroke="2.4" />
    </button>
  </div>
</template>
