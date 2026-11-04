<script setup lang="ts">
import type { ProductSummary } from '#shared/types/api'

defineProps<{ product: ProductSummary }>()
const { t } = useI18n()
</script>

<template>
  <article class="card p-2.5 flex flex-col h-full">
    <NuxtLinkLocale :to="`/product/${product.slug}`" class="block relative" tabindex="-1">
      <ProductImage :image="product.image" :emoji="product.emoji" :color="product.color" :alt="product.name" class="aspect-square rounded-xl" />
      <span v-if="product.discount_percent" class="absolute top-2 start-2 rounded-full bg-accent-500 text-white text-[11px] font-bold px-2 py-0.5">
        {{ t('product.off', { n: product.discount_percent }) }}
      </span>
      <span v-if="!product.in_stock" class="absolute inset-0 rounded-xl bg-white/60 grid place-items-center">
        <span class="rounded-full bg-ink/80 text-white text-xs font-bold px-2.5 py-1">{{ t('product.outOfStock') }}</span>
      </span>
    </NuxtLinkLocale>
    <NuxtLinkLocale :to="`/product/${product.slug}`" class="mt-2 text-sm font-semibold leading-snug line-clamp-2 min-h-[2.5em] hover:text-brand-700">
      {{ product.name }}
    </NuxtLinkLocale>
    <p class="text-xs text-muted mt-0.5 truncate">{{ product.unit_label }}</p>
    <div class="mt-auto pt-2 space-y-2">
      <PriceTag :price="product.price" :sale-price="product.sale_price" />
      <AddToCart :product="product" />
    </div>
  </article>
</template>
