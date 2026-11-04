<script setup lang="ts">
import type { Paginated, ProductSummary } from '#shared/types/api'

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const { $api } = useNuxtApp()

const SORTS = ['recommended', 'best', 'price_asc', 'price_desc', 'discount', 'newest'] as const
const slug = computed(() => String(route.params.slug))
const sub = computed(() => (typeof route.query.sub === 'string' ? route.query.sub : ''))
const sort = computed(() => (typeof route.query.sort === 'string' ? route.query.sort : 'recommended'))

const { data: categories } = await useCategories()
const category = computed(() => categories.value?.find((c) => c.slug === slug.value))
if (categories.value && !category.value) {
  throw createError({ statusCode: 404, statusMessage: 'Category not found', fatal: true })
}

// Filters and sort live in the URL so results can be shared and survive reloads (FE-303).
const filters = computed(() => ({ sub: sub.value || undefined, sort: sort.value }))
const { data: firstPage, status } = await useApiFetch<Paginated<ProductSummary>>(() => `/categories/${slug.value}/products/`, {
  query: filters,
})

const more = ref<ProductSummary[]>([])
const nextPage = ref<number | null>(null)
const loadingMore = ref(false)
watch(firstPage, (page) => {
  more.value = []
  nextPage.value = page?.next ?? null
}, { immediate: true })

const products = computed(() => [...(firstPage.value?.results ?? []), ...more.value])

async function loadMore() {
  if (!nextPage.value) return
  loadingMore.value = true
  try {
    const page = await $api<Paginated<ProductSummary>>(`/categories/${slug.value}/products/`, { query: { ...filters.value, page: nextPage.value } })
    more.value.push(...page.results)
    nextPage.value = page.next
  } finally {
    loadingMore.value = false
  }
}

function setQuery(patch: Record<string, string | undefined>) {
  router.replace({ query: { ...route.query, ...patch } })
}

useSeoMeta({
  title: () => category.value?.name ?? '',
  description: () => `${category.value?.name} – ${t('brand.tagline')}`,
})
</script>

<template>
  <div v-if="category">
    <nav class="text-xs text-muted mb-3 flex items-center gap-1" aria-label="Breadcrumb">
      <NuxtLinkLocale to="/" class="hover:text-brand-700">{{ t('nav.home') }}</NuxtLinkLocale>
      <AppIcon name="chevron-end" :size="14" />
      <NuxtLinkLocale to="/categories" class="hover:text-brand-700">{{ t('nav.categories') }}</NuxtLinkLocale>
    </nav>

    <div class="flex items-center gap-3 mb-4">
      <span class="size-14 rounded-2xl grid place-items-center text-3xl shrink-0" :style="{ backgroundColor: category.color }" aria-hidden="true">
        {{ category.emoji }}
      </span>
      <div>
        <h1 class="text-2xl font-extrabold leading-tight">{{ category.name }}</h1>
        <p class="text-xs text-muted">{{ t('category.count', { n: firstPage?.count ?? category.product_count }) }}</p>
      </div>
    </div>

    <div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-4">
      <div class="-mx-4 px-4 sm:mx-0 sm:px-0 flex gap-2 overflow-x-auto no-scrollbar flex-1">
        <button type="button" class="chip" :class="!sub && 'chip-active'" @click="setQuery({ sub: undefined })">{{ t('common.all') }}</button>
        <button
          v-for="s in category.children"
          :key="s.id"
          type="button"
          class="chip"
          :class="sub === s.slug && 'chip-active'"
          @click="setQuery({ sub: s.slug })"
        >
          {{ s.name }}
        </button>
      </div>
      <label class="relative shrink-0 flex items-center gap-2 text-sm">
        <AppIcon name="sliders" :size="18" class="text-muted" />
        <span class="sr-only">{{ t('sort.label') }}</span>
        <select
          :value="sort"
          class="field h-9 w-auto ps-3 pe-9 text-xs font-bold appearance-none"
          @change="setQuery({ sort: ($event.target as HTMLSelectElement).value })"
        >
          <option v-for="s in SORTS" :key="s" :value="s">{{ t(`sort.${s}`) }}</option>
        </select>
        <AppIcon name="chevron-down" :size="16" class="absolute end-2.5 pointer-events-none" />
      </label>
    </div>

    <ProductGrid :products="products" :loading="status === 'pending'" />
    <EmptyState v-if="status === 'success' && !products.length" emoji="🧺" :title="t('category.empty')" />

    <div v-if="nextPage" class="text-center mt-6">
      <button type="button" class="btn-outline px-8" :disabled="loadingMore" @click="loadMore">{{ t('common.loadMore') }}</button>
    </div>
  </div>
</template>
