<script setup lang="ts">
const props = withDefaults(defineProps<{ name: IconName; size?: number | string; stroke?: number }>(), { size: 22, stroke: 2 })
const directional = computed(() => props.name.endsWith('-end') || props.name.endsWith('-start'))
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -->
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    :stroke-width="stroke"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    class="shrink-0"
    :class="directional && 'rtl:-scale-x-100'"
    v-html="ICONS[name]"
  />
</template>
