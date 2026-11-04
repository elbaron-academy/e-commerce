<script setup lang="ts">
const { locale, setLocale, t } = useI18n()
const auth = useAuthStore()
const { $api } = useNuxtApp()

async function toggle() {
  const target = locale.value === 'ar' ? 'en' : 'ar'
  await setLocale(target)
  if (auth.isLoggedIn) $api('/me/', { method: 'PATCH', body: { language: target } }).catch(() => {})
}
</script>

<template>
  <button type="button" class="btn-ghost h-9 px-2.5 text-sm" @click="toggle">
    <AppIcon name="globe" :size="18" />
    <span>{{ t('header.switchLang') }}</span>
  </button>
</template>
