<script setup lang="ts">
const online = useOnline()
const { t } = useI18n()
</script>

<template>
  <div v-if="!online" class="bg-ink text-white text-xs font-semibold py-1.5 px-4 flex items-center justify-center gap-2" role="status">
    <AppIcon name="wifi-off" :size="16" />
    {{ t('pwa.offline') }}
  </div>
</template>
