<template>
  <div class="min-h-dvh flex flex-col">
    <OfflineBanner />
    <AppHeader />
    <main class="flex-1 w-full max-w-6xl mx-auto px-4 pt-4 pb-24 md:pb-12">
      <slot />
    </main>
    <AppFooter />
    <BottomNav />
    <ToastHost />
    <ClientOnly>
      <PwaInstallBanner />
      <PwaUpdateToast />
    </ClientOnly>
  </div>
</template>
