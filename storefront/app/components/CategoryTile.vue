<script setup lang="ts">
import type { CategoryNode } from '#shared/types/api'

defineProps<{ category: CategoryNode }>()
</script>

<template>
  <NuxtLinkLocale :to="`/category/${category.slug}`" class="group flex flex-col items-center gap-1.5 text-center">
    <span
      class="grid place-items-center w-full aspect-square max-w-20 rounded-2xl text-3xl md:text-4xl transition group-hover:scale-105 group-active:scale-95"
      :style="{ backgroundColor: category.color }"
    >
      {{ category.emoji }}
    </span>
    <span class="text-xs md:text-sm font-semibold leading-tight line-clamp-2">{{ category.name }}</span>
  </NuxtLinkLocale>
</template>
