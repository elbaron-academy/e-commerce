<script setup lang="ts">
withDefaults(defineProps<{ image?: string | null; emoji: string; color: string; alt: string; size?: 'xs' | 'sm' | 'md' | 'lg' }>(), {
  image: null,
  size: 'md',
})
const emojiSize = { xs: 'text-2xl', sm: 'text-4xl', md: 'text-6xl', lg: 'text-[8rem] md:text-[10rem]' }
</script>

<template>
  <div class="relative overflow-hidden grid place-items-center" :style="{ backgroundColor: color }">
    <img v-if="image" :src="image" :alt="alt" loading="lazy" decoding="async" class="absolute inset-0 size-full object-contain p-2">
    <span v-else role="img" :aria-label="alt" class="select-none leading-none drop-shadow-sm" :class="emojiSize[size]">{{ emoji }}</span>
  </div>
</template>
