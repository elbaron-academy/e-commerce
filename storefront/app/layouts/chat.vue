<!-- Full-height layout for the chat: header on top, the page fills the rest, no footer or bottom bar. -->
<template>
  <div class="h-dvh flex flex-col">
    <OfflineBanner />
    <AppHeader />
    <main class="flex-1 min-h-0 w-full max-w-3xl mx-auto md:px-4 md:py-4 flex flex-col">
      <slot />
    </main>
    <ToastHost />
  </div>
</template>
