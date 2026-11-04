<script setup lang="ts">
import type { NuxtError } from '#app'

const props = defineProps<{ error: NuxtError }>()
useAppHead()
const { t } = useI18n()
const localePath = useLocalePath()
const is404 = computed(() => props.error.statusCode === 404)
useSeoMeta({ title: () => (is404.value ? t('error.notFound') : t('error.generic')), robots: 'noindex' })
</script>

<template>
  <NuxtLayout>
    <EmptyState :emoji="is404 ? '🧭' : '😕'" :title="is404 ? t('error.notFound') : t('error.generic')">
      <button type="button" class="btn-primary px-6" @click="clearError({ redirect: localePath('/') })">{{ t('common.goHome') }}</button>
    </EmptyState>
  </NuxtLayout>
</template>
