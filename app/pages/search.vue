<script setup lang="ts">
import type { Paginated, ProductSummary } from '#shared/types/api'

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const localePath = useLocalePath()
const recent = useRecentSearches()

const q = computed(() => (typeof route.query.q === 'string' ? route.query.q.trim() : ''))
const tag = computed(() => (typeof route.query.tag === 'string' ? route.query.tag : ''))
const sort = computed(() => (typeof route.query.sort === 'string' ? route.query.sort : 'recommended'))
const active = computed(() => !!(q.value || tag.value))

const { data, status } = await useApiFetch<Paginated<ProductSummary>>('/search/', {
  query: computed(() => ({ q: q.value || undefined, tag: tag.value || undefined, sort: sort.value, page_size: 48 })),
})

onMounted(() => recent.read())
watch(q, (term) => import.meta.client && term && recent.add(term), { immediate: true })

const popular = computed(() =>
  locale.value === 'ar'
    ? ['لبن', 'عيش', 'بيض', 'طماطم', 'فراخ', 'مياه', 'أرز', 'جبنة']
    : ['Milk', 'Bread', 'Eggs', 'Tomato', 'Chicken', 'Water', 'Rice', 'Cheese'],
)

const heading = computed(() => {
  if (tag.value) return t(`search.tags.${tag.value}`)
  if (status.value === 'success' && !data.value?.count) return t('search.noResults', { q: q.value })
  return t('search.results', { n: data.value?.count ?? 0, q: q.value })
})

function searchFor(term: string) {
  router.push({ path: localePath('/search'), query: { q: term } })
}

useSeoMeta({
  title: () => (active.value ? heading.value : t('search.title')),
  robots: () => (q.value ? 'noindex, follow' : 'index, follow'),
})
</script>

<template>
  <div>
    <SearchBox class="md:hidden mb-5" :initial="q" :autofocus="!active" />

    <template v-if="active">
      <h1 class="text-xl font-extrabold mb-4">{{ heading }}</h1>
      <ProductGrid :products="data?.results ?? []" :loading="status === 'pending'" />
      <div v-if="status === 'success' && !data?.count" class="text-center py-10">
        <p class="text-5xl mb-3" aria-hidden="true">🔎</p>
        <p class="text-sm text-muted mb-4">{{ t('search.tryAnother') }}</p>
        <div class="flex flex-wrap justify-center gap-2">
          <button v-for="term in popular" :key="term" type="button" class="chip" @click="searchFor(term)">{{ term }}</button>
        </div>
      </div>
    </template>

    <div v-else class="space-y-6">
      <ClientOnly>
        <section v-if="recent.items.value.length">
          <div class="flex items-center justify-between mb-2.5">
            <h2 class="font-extrabold">{{ t('search.recent') }}</h2>
            <button type="button" class="text-sm font-bold text-brand-700" @click="recent.clear()">{{ t('search.clear') }}</button>
          </div>
          <div class="flex flex-wrap gap-2">
            <button v-for="term in recent.items.value" :key="term" type="button" class="chip" @click="searchFor(term)">
              <AppIcon name="clock" :size="15" class="text-muted" /> {{ term }}
            </button>
          </div>
        </section>
      </ClientOnly>
      <section>
        <h2 class="font-extrabold mb-2.5">{{ t('search.popular') }}</h2>
        <div class="flex flex-wrap gap-2">
          <button v-for="term in popular" :key="term" type="button" class="chip" @click="searchFor(term)">{{ term }}</button>
        </div>
      </section>
    </div>
  </div>
</template>
