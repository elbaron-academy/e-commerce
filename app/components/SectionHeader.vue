<script setup lang="ts">
defineProps<{ title: string; to?: string | null }>()
const { t } = useI18n()
</script>

<template>
  <div class="flex items-center justify-between gap-3 mb-3">
    <h2 class="section-title">{{ title }}</h2>
    <NuxtLinkLocale v-if="to" :to="to" class="text-sm font-bold text-brand-700 inline-flex items-center gap-0.5 shrink-0">
      {{ t('common.seeAll') }}
      <AppIcon name="chevron-end" :size="16" :stroke="2.5" />
    </NuxtLinkLocale>
  </div>
</template>
