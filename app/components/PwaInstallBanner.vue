<script setup lang="ts">
// Shows the install prompt (Android/desktop) or Add to Home Screen steps (iOS Safari).
const pwa = usePWA()
const { t } = useI18n()
const IOS_KEY = 'rk_ios_hint_dismissed'

const ready = ref(false)
const iosHint = ref(false)

onMounted(() => {
  const ua = navigator.userAgent
  const standalone = window.matchMedia('(display-mode: standalone)').matches || (navigator as Navigator & { standalone?: boolean }).standalone
  let dismissed = false
  try {
    dismissed = localStorage.getItem(IOS_KEY) === '1'
  } catch {}
  iosHint.value = /iphone|ipad|ipod/i.test(ua) && /safari/i.test(ua) && !/crios|fxios/i.test(ua) && !standalone && !dismissed
  // Give people a moment with the store before asking.
  setTimeout(() => (ready.value = true), 6000)
})

const visible = computed(() => ready.value && ((pwa?.showInstallPrompt && !pwa?.isPWAInstalled) || iosHint.value))

function later() {
  if (iosHint.value) {
    iosHint.value = false
    try {
      localStorage.setItem(IOS_KEY, '1')
    } catch {}
  } else {
    pwa?.cancelInstall()
  }
}
</script>

<template>
  <Transition enter-from-class="translate-y-4 opacity-0" enter-active-class="transition duration-300" leave-to-class="translate-y-4 opacity-0" leave-active-class="transition duration-200">
    <div
      v-if="visible"
      class="fixed z-40 inset-x-3 bottom-[calc(4.75rem+env(safe-area-inset-bottom))] md:bottom-5 md:start-auto md:end-5 md:w-96 card shadow-2xl shadow-black/10 p-4 flex gap-3"
      role="dialog"
      :aria-label="t('pwa.installTitle')"
    >
      <img src="/pwa-192x192.png" alt="" width="48" height="48" class="size-12 rounded-xl shrink-0">
      <div class="min-w-0 flex-1">
        <p class="font-extrabold text-sm">{{ t('pwa.installTitle') }}</p>
        <p class="text-xs text-muted mt-0.5">{{ iosHint ? t('pwa.iosHint') : t('pwa.installText') }}</p>
        <div class="flex gap-2 mt-3">
          <button v-if="!iosHint" type="button" class="btn-primary h-9 px-4" @click="pwa?.install()">
            <AppIcon name="download" :size="16" /> {{ t('pwa.install') }}
          </button>
          <button type="button" class="btn-ghost h-9 px-3" @click="later">{{ t('pwa.later') }}</button>
        </div>
      </div>
    </div>
  </Transition>
</template>
