<script setup lang="ts">
const { t } = useI18n()
const route = useRoute()
const auth = useAuthStore()
const { data: categories } = useCategories()
const onSearchPage = computed(() => /^\/(en\/)?search/.test(route.path))
</script>

<template>
  <header class="sticky top-0 z-30 bg-white/95 backdrop-blur border-b border-line">
    <div class="max-w-6xl mx-auto px-4 h-14 md:h-16 flex items-center gap-4">
      <NuxtLinkLocale to="/" class="flex items-center gap-2 shrink-0">
        <img src="/logo.svg" alt="" width="36" height="36" class="size-8 md:size-9">
        <span class="font-extrabold text-lg text-brand-700 leading-none">{{ t('brand.name') }}</span>
      </NuxtLinkLocale>

      <SearchBox class="hidden md:block flex-1 max-w-xl mx-auto" />

      <div class="ms-auto md:ms-0 flex items-center gap-1">
        <LangSwitch />
        <NuxtLinkLocale :to="auth.isLoggedIn ? '/account' : '/login'" class="hidden md:inline-flex btn-ghost h-10 px-3">
          <AppIcon name="user" :size="20" />
          <span>{{ auth.isLoggedIn ? (auth.user?.name || t('nav.account')) : t('header.login') }}</span>
        </NuxtLinkLocale>
        <NuxtLinkLocale to="/cart" class="hidden md:inline-flex btn-ghost h-10 px-3 relative" :aria-label="t('nav.cart')">
          <span class="relative">
            <AppIcon name="cart" :size="22" />
            <CartBadge class="absolute -top-2 -end-2.5" />
          </span>
          <span>{{ t('nav.cart') }}</span>
        </NuxtLinkLocale>
      </div>
    </div>

    <div v-if="!onSearchPage" class="md:hidden px-4 pb-3">
      <NuxtLinkLocale to="/search" class="field flex items-center gap-2.5 bg-canvas border-transparent text-muted">
        <AppIcon name="search" :size="20" />
        <span class="truncate">{{ t('header.searchPlaceholder') }}</span>
      </NuxtLinkLocale>
    </div>

    <nav v-if="categories?.length" class="hidden md:block border-t border-line">
      <ul class="max-w-6xl mx-auto px-4 flex gap-1 overflow-x-auto no-scrollbar">
        <li>
          <NuxtLinkLocale to="/categories" class="flex items-center gap-1.5 px-3 h-11 text-sm font-bold text-brand-700 whitespace-nowrap">
            <AppIcon name="grid" :size="18" /> {{ t('category.allCategories') }}
          </NuxtLinkLocale>
        </li>
        <li v-for="c in categories" :key="c.id">
          <NuxtLinkLocale
            :to="`/category/${c.slug}`"
            class="flex items-center gap-1.5 px-3 h-11 text-sm font-semibold whitespace-nowrap text-ink/80 hover:text-brand-700"
            active-class="!text-brand-700"
          >
            <span>{{ c.emoji }}</span> {{ c.name }}
          </NuxtLinkLocale>
        </li>
      </ul>
    </nav>
  </header>
</template>
