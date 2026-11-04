<script setup lang="ts">
const chat = useChatStore()
</script>

<template>
  <span
    v-if="chat.unread"
    class="min-w-[18px] h-[18px] px-1 rounded-full bg-accent-500 text-white text-[10px] font-bold grid place-items-center ring-2 ring-white"
  >
    {{ chat.unread > 99 ? '99+' : chat.unread }}
  </span>
</template>
