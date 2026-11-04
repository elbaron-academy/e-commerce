<script setup lang="ts">
const { t } = useI18n()
const route = useRoute()

const items = [
  { key: 'home', to: '/', icon: 'home', label: 'nav.home', match: (p: string) => p === '/' },
  { key: 'categories', to: '/categories', icon: 'grid', label: 'nav.categories', match: (p: string) => p.startsWith('/categor') },
  { key: 'cart', to: '/cart', icon: 'cart', label: 'nav.cart', match: (p: string) => p.startsWith('/cart') || p.startsWith('/checkout') },
  { key: 'orders', to: '/orders', icon: 'package', label: 'nav.orders', match: (p: string) => p.startsWith('/orders') },
  { key: 'account', to: '/account', icon: 'user', label: 'nav.account', match: (p: string) => p.startsWith('/account') || p.startsWith('/login') },
] as const

const path = computed(() => route.path.replace(/^\/en(?=\/|$)/, '') || '/')
</script>

<template>
  <nav
    v-if="!route.meta.hideBottomNav"
    class="md:hidden fixed bottom-0 inset-x-0 z-30 bg-white/95 backdrop-blur border-t border-line pb-safe"
    :aria-label="t('nav.main')"
  >
    <ul class="grid grid-cols-5 h-16">
      <li v-for="item in items" :key="item.key">
        <NuxtLinkLocale
          :to="item.to"
          class="flex flex-col items-center justify-center gap-1 h-full text-[11px] font-bold transition"
          :class="item.match(path) ? 'text-brand-700' : 'text-muted'"
          :aria-current="item.match(path) ? 'page' : undefined"
        >
          <span class="relative">
            <AppIcon :name="item.icon" :size="23" :stroke="item.match(path) ? 2.4 : 2" />
            <CartBadge v-if="item.key === 'cart'" class="absolute -top-1.5 -end-2.5" />
          </span>
          {{ t(item.label) }}
        </NuxtLinkLocale>
      </li>
    </ul>
  </nav>
</template>
