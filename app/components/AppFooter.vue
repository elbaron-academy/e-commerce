<script setup lang="ts">
const { t } = useI18n()
const year = new Date().getFullYear()
</script>

<template>
  <footer class="border-t border-line bg-white mb-16 md:mb-0">
    <div class="max-w-6xl mx-auto px-4 py-6 flex flex-col md:flex-row md:items-center gap-3 text-sm text-muted">
      <div class="flex items-center gap-2">
        <img src="/logo.svg" alt="" width="24" height="24" class="size-6">
        <span>{{ t('footer.about') }}</span>
      </div>
      <span class="md:ms-auto">{{ t('footer.rights', { year }) }}</span>
    </div>
  </footer>
</template>
