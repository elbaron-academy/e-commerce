<script setup lang="ts">
// "New version" prompt. We ask before reloading so nobody loses a checkout in progress.
const pwa = usePWA()
const { t } = useI18n()

watch(
  () => pwa?.offlineReady,
  (ready) => {
    if (ready) setTimeout(() => pwa?.cancelPrompt(), 4000)
  },
)
</script>

<template>
  <div
    v-if="pwa?.needRefresh || pwa?.offlineReady"
    class="fixed z-50 top-3 inset-x-3 md:top-auto md:bottom-5 md:end-auto md:start-5 md:w-96 rounded-2xl bg-ink text-white shadow-2xl p-3.5 flex items-center gap-3"
    role="status"
  >
    <AppIcon :name="pwa.needRefresh ? 'refresh' : 'check'" :size="20" class="text-brand-300" />
    <p class="text-sm font-semibold flex-1">{{ pwa.needRefresh ? t('pwa.updateAvailable') : t('pwa.offlineReady') }}</p>
    <button v-if="pwa.needRefresh" type="button" class="btn h-9 px-4 bg-white text-ink" @click="pwa.updateServiceWorker()">
      {{ t('pwa.reload') }}
    </button>
    <button type="button" class="grid place-items-center size-8 rounded-lg hover:bg-white/10" :aria-label="t('common.close')" @click="pwa.cancelPrompt()">
      <AppIcon name="x" :size="18" />
    </button>
  </div>
</template>
