<script setup lang="ts">
import type { ProductSummary } from '#shared/types/api'

defineProps<{ title: string; to?: string | null; products: ProductSummary[] }>()
</script>

<template>
  <section v-if="products.length">
    <SectionHeader :title="title" :to="to" />
    <div class="-mx-4 px-4 flex gap-3 overflow-x-auto no-scrollbar snap-x snap-mandatory scroll-px-4 pb-1">
      <div v-for="p in products" :key="p.id" class="w-[44%] min-[480px]:w-44 md:w-48 shrink-0 snap-start">
        <ProductCard :product="p" />
      </div>
    </div>
  </section>
</template>
