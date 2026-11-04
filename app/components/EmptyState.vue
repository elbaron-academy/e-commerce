<script setup lang="ts">
defineProps<{ emoji: string; title: string; text?: string }>()
</script>

<template>
  <div class="text-center py-14 px-6 max-w-sm mx-auto">
    <div class="text-6xl mb-4" aria-hidden="true">{{ emoji }}</div>
    <h2 class="text-lg font-extrabold">{{ title }}</h2>
    <p v-if="text" class="text-sm text-muted mt-1.5">{{ text }}</p>
    <div class="mt-5"><slot /></div>
  </div>
</template>
