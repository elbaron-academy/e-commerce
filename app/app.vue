<script setup lang="ts">
useAppHead()
</script>

<template>
  <NuxtPwaManifest />
  <NuxtLoadingIndicator color="#0e7c5a" :height="3" />
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
</template>
