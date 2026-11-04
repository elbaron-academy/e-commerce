<script setup lang="ts">
import type { Paginated, ProductDetail, ProductSummary } from '#shared/types/api'

const route = useRoute()
const { t } = useI18n()
const { money, date, qty } = useFormat()
const config = useRuntimeConfig()

const slug = computed(() => String(route.params.slug))
const { data: product, error } = await useApiFetch<ProductDetail>(() => `/products/${slug.value}/`)
if (error.value || !product.value) {
  throw createError({ statusCode: 404, statusMessage: 'Product not found', fatal: true })
}

const { data: related } = await useApiFetch<Paginated<ProductSummary>>('/products/', {
  query: computed(() => ({ category: product.value?.category.slug, exclude: slug.value, page_size: 10 })),
})

const selectedSku = ref(product.value.default_sku)
watch(() => product.value?.default_sku, (sku) => sku && (selectedSku.value = sku))
const variant = computed(() => product.value!.variants.find((v) => v.sku === selectedSku.value) ?? product.value!.variants[0]!)
const discount = computed(() => (variant.value.sale_price ? Math.round((1 - variant.value.sale_price / variant.value.price) * 100) : 0))

// SEO (FE-301): meta tags + schema.org Product
useSeoMeta({
  title: () => product.value?.name,
  description: () => `${product.value?.name} (${variant.value.label}). ${product.value?.description}`,
  ogTitle: () => product.value?.name,
  ogDescription: () => product.value?.description,
  ogImage: () => product.value?.image || `${config.public.siteUrl}/pwa-512x512.png`,
  ogType: 'website',
})
useHead(() => ({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: JSON.stringify({
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: product.value?.name,
        sku: variant.value.sku,
        brand: { '@type': 'Brand', name: product.value?.brand },
        category: product.value?.category.name,
        description: product.value?.description,
        image: product.value?.image ?? undefined,
        offers: {
          '@type': 'Offer',
          priceCurrency: 'EGP',
          price: variant.value.sale_price ?? variant.value.price,
          availability: variant.value.in_stock ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
          url: `${config.public.siteUrl}${route.path}`,
        },
      }),
    },
  ],
}))
</script>

<template>
  <div v-if="product">
    <nav class="text-xs text-muted mb-3 flex items-center gap-1 min-w-0" aria-label="Breadcrumb">
      <NuxtLinkLocale to="/" class="hover:text-brand-700 shrink-0">{{ t('nav.home') }}</NuxtLinkLocale>
      <AppIcon name="chevron-end" :size="14" />
      <NuxtLinkLocale :to="`/category/${product.category.slug}`" class="hover:text-brand-700 shrink-0">{{ product.category.name }}</NuxtLinkLocale>
      <AppIcon name="chevron-end" :size="14" />
      <span class="truncate">{{ product.name }}</span>
    </nav>

    <div class="grid md:grid-cols-2 gap-6 md:gap-10">
      <div class="relative">
        <ProductImage size="lg" :image="product.image" :emoji="product.emoji" :color="product.color" :alt="product.name" class="aspect-square rounded-3xl" />
        <span v-if="discount" class="absolute top-4 start-4 rounded-full bg-accent-500 text-white text-sm font-bold px-3 py-1">
          {{ t('product.off', { n: discount }) }}
        </span>
      </div>

      <div class="flex flex-col gap-5">
        <div>
          <p class="text-sm font-bold text-brand-700">{{ product.brand }}</p>
          <h1 class="text-2xl md:text-3xl font-extrabold leading-tight mt-1">{{ product.name }}</h1>
          <p class="text-sm text-muted mt-1">{{ variant.label }}</p>
        </div>

        <div>
          <PriceTag size="lg" :price="variant.price" :sale-price="variant.sale_price" />
          <p v-if="variant.sale_price && product.sale_ends_at" class="text-xs text-accent-700 font-bold mt-1.5 flex items-center gap-1">
            <AppIcon name="clock" :size="14" />
            {{ t('product.offerEnds', { date: date(`${product.sale_ends_at}T12:00:00`, { weekday: 'long', day: 'numeric', month: 'long' }) }) }}
          </p>
        </div>

        <div v-if="product.variants.length > 1">
          <p class="label">{{ t('product.chooseSize') }}</p>
          <div class="flex flex-wrap gap-2" role="radiogroup" :aria-label="t('product.chooseSize')">
            <button
              v-for="v in product.variants"
              :key="v.sku"
              type="button"
              role="radio"
              :aria-checked="v.sku === selectedSku"
              :disabled="!v.in_stock"
              class="rounded-xl border-2 px-3.5 py-2 text-start transition disabled:opacity-40"
              :class="v.sku === selectedSku ? 'border-brand-600 bg-brand-50' : 'border-line bg-white hover:border-brand-200'"
              @click="selectedSku = v.sku"
            >
              <span class="block text-sm font-bold">{{ v.label }}</span>
              <span class="block text-xs" :class="v.sale_price ? 'text-accent-600 font-bold' : 'text-muted'">{{ money(v.sale_price ?? v.price) }}</span>
            </button>
          </div>
        </div>

        <div class="space-y-2 max-w-sm">
          <p v-if="variant.in_stock && variant.stock <= 5" class="text-sm font-bold text-accent-700">
            {{ t('product.lowStock', { n: qty(variant.stock, product.sold_by_weight) }) }}
          </p>
          <AddToCart :product="product" :sku="selectedSku" size="lg" />
          <p v-if="product.sold_by_weight" class="text-xs text-muted flex gap-1.5">
            <AppIcon name="alert" :size="16" /> {{ t('product.weightNote') }}
          </p>
        </div>

        <div class="card p-3.5 flex items-center gap-3 text-sm font-semibold">
          <span class="grid place-items-center size-9 rounded-xl bg-brand-50 text-brand-700"><AppIcon name="truck" :size="20" /></span>
          {{ t('product.deliveryPromise') }}
        </div>

        <section class="card p-4">
          <h2 class="font-extrabold mb-1.5">{{ t('product.description') }}</h2>
          <p class="text-sm text-muted leading-relaxed">{{ product.description }}</p>
        </section>
      </div>
    </div>

    <ProductRow
      v-if="related?.results.length"
      class="mt-10"
      :title="t('product.related')"
      :to="`/category/${product.category.slug}`"
      :products="related.results"
    />
  </div>
</template>
