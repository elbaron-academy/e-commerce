<script setup lang="ts">
import type { DeliveryInfo, HomeData } from '#shared/types/api'

const { t } = useI18n()
const { money } = useFormat()

const [{ data: home }, { data: categories }, { data: delivery }] = await Promise.all([
  useApiFetch<HomeData>('/home/'),
  useCategories(),
  useApiFetch<DeliveryInfo>('/delivery/info/', { key: 'delivery-info' }),
])

useSeoMeta({
  description: () => t('brand.tagline'),
  ogTitle: () => t('brand.name'),
  ogDescription: () => t('brand.tagline'),
  ogImage: '/pwa-512x512.png',
})

const tones = {
  green: 'bg-brand-600 text-white',
  orange: 'bg-accent-500 text-white',
  blue: 'bg-sky-700 text-white',
}
</script>

<template>
  <div class="space-y-8">
    <ul class="-mx-4 px-4 flex gap-2 overflow-x-auto no-scrollbar">
      <li class="chip border-transparent">
        <AppIcon name="zap" :size="16" class="text-accent-500" /> {{ t('home.express') }}
      </li>
      <li v-if="delivery" class="chip border-transparent">
        <AppIcon name="truck" :size="16" class="text-brand-600" /> {{ t('home.freeDelivery', { amount: money(delivery.free_delivery_threshold) }) }}
      </li>
      <li class="chip border-transparent">
        <AppIcon name="store" :size="16" class="text-brand-600" /> {{ t('home.pickup') }}
      </li>
    </ul>

    <section v-if="home?.banners.length" class="-mx-4 px-4 flex gap-3 overflow-x-auto no-scrollbar snap-x snap-mandatory scroll-px-4">
      <NuxtLinkLocale
        v-for="b in home.banners"
        :key="b.id"
        :to="b.link"
        class="relative shrink-0 snap-start w-[86%] sm:w-[60%] lg:w-[calc((100%-1.5rem)/3)] min-h-44 rounded-3xl p-5 overflow-hidden flex flex-col"
        :class="tones[b.tone]"
      >
        <h2 class="text-xl font-extrabold leading-snug max-w-[78%]">{{ b.title }}</h2>
        <p class="text-sm opacity-90 mt-1 max-w-[72%]">{{ b.subtitle }}</p>
        <span class="mt-auto pt-4">
          <span class="inline-flex items-center gap-1 rounded-full bg-white text-ink text-sm font-bold px-4 h-9">
            {{ b.cta }} <AppIcon name="chevron-end" :size="16" :stroke="2.5" />
          </span>
        </span>
        <span class="absolute -bottom-1 end-3 text-7xl select-none" aria-hidden="true">{{ b.emoji }}</span>
      </NuxtLinkLocale>
    </section>

    <section v-if="categories?.length">
      <SectionHeader :title="t('home.categories')" to="/categories" />
      <div class="grid grid-cols-4 md:grid-cols-8 gap-x-3 gap-y-4">
        <CategoryTile v-for="c in categories" :key="c.id" :category="c" />
      </div>
    </section>

    <ProductRow v-for="s in home?.sections" :key="s.key" :title="s.title" :to="s.link" :products="s.products" />
  </div>
</template>
