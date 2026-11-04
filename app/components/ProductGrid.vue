<script setup lang="ts">
import type { ProductSummary } from '#shared/types/api'

withDefaults(defineProps<{ products: ProductSummary[]; loading?: boolean; skeletons?: number }>(), { loading: false, skeletons: 10 })
</script>

<template>
  <div class="grid grid-cols-2 min-[560px]:grid-cols-3 lg:grid-cols-5 gap-3">
    <template v-if="loading && !products.length">
      <div v-for="i in skeletons" :key="i" class="card p-2.5 animate-pulse">
        <div class="aspect-square rounded-xl bg-canvas" />
        <div class="h-3.5 rounded bg-canvas mt-3 w-4/5" />
        <div class="h-3 rounded bg-canvas mt-2 w-1/3" />
        <div class="h-10 rounded-xl bg-canvas mt-3" />
      </div>
    </template>
    <ProductCard v-for="p in products" :key="p.id" :product="p" />
  </div>
</template>
