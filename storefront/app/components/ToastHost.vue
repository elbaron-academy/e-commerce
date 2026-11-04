<script setup lang="ts">
const { toasts, dismiss } = useToast()
const tones = { default: 'bg-ink text-white', success: 'bg-brand-700 text-white', error: 'bg-danger text-white' }
</script>

<template>
  <div class="fixed z-50 top-20 inset-x-0 flex flex-col items-center gap-2 px-4 pointer-events-none" aria-live="polite">
    <TransitionGroup enter-from-class="-translate-y-2 opacity-0" enter-active-class="transition duration-200" leave-to-class="opacity-0" leave-active-class="transition duration-200">
      <button
        v-for="toast in toasts"
        :key="toast.id"
        type="button"
        class="pointer-events-auto rounded-full shadow-lg px-4 py-2.5 text-sm font-semibold max-w-md"
        :class="tones[toast.tone]"
        @click="dismiss(toast.id)"
      >
        {{ toast.message }}
      </button>
    </TransitionGroup>
  </div>
</template>
