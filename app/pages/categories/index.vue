<script setup lang="ts">
const { t } = useI18n()
const { data: categories } = await useCategories()
useSeoMeta({ title: () => t('nav.categories') })
</script>

<template>
  <div>
    <h1 class="text-2xl font-extrabold mb-4">{{ t('nav.categories') }}</h1>
    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
      <div v-for="c in categories" :key="c.id" class="card p-4 flex gap-4">
        <NuxtLinkLocale
          :to="`/category/${c.slug}`"
          class="size-20 rounded-2xl grid place-items-center text-4xl shrink-0"
          :style="{ backgroundColor: c.color }"
          tabindex="-1"
          aria-hidden="true"
        >
          {{ c.emoji }}
        </NuxtLinkLocale>
        <div class="min-w-0">
          <NuxtLinkLocale :to="`/category/${c.slug}`" class="font-extrabold hover:text-brand-700">{{ c.name }}</NuxtLinkLocale>
          <p class="text-xs text-muted">{{ t('category.count', { n: c.product_count }) }}</p>
          <div class="flex flex-wrap gap-1.5 mt-2.5">
            <NuxtLinkLocale
              v-for="s in c.children"
              :key="s.id"
              :to="{ path: `/category/${c.slug}`, query: { sub: s.slug } }"
              class="text-xs font-semibold rounded-full bg-canvas px-2.5 py-1 hover:bg-brand-50 hover:text-brand-700"
            >
              {{ s.name }}
            </NuxtLinkLocale>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
