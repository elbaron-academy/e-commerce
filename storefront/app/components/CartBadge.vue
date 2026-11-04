<script setup lang="ts">
const cart = useCartStore()
</script>

<template>
  <span
    v-if="cart.loaded && cart.count"
    class="min-w-[18px] h-[18px] px-1 rounded-full bg-accent-500 text-white text-[10px] font-bold grid place-items-center ring-2 ring-white"
  >
    {{ cart.count > 99 ? '99+' : cart.count }}
  </span>
</template>
