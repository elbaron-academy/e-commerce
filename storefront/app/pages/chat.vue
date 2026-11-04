<script setup lang="ts">
import type { Order } from '#shared/types/api'
import type { ChatItem } from '~/composables/useChat'

definePageMeta({ middleware: 'auth', layout: 'chat', hideBottomNav: true, compactHeader: true })

const { t } = useI18n()
const { date } = useFormat()
const { $api } = useNuxtApp()
const route = useRoute()
const router = useRouter()
const toast = useToast()
const online = useOnline()
const chat = useChat()
const { items, hasOlder, loading, loadFailed, loadingOlder } = chat

useSeoMeta({ title: () => t('chat.title'), robots: 'noindex' })

const MAX_PHOTO_MB = 8
const scroller = ref<HTMLElement>()
const textarea = ref<HTMLTextAreaElement>()
const fileInput = ref<HTMLInputElement>()
const text = ref('')
const photo = ref<File | null>(null)
const photoPreview = ref<string | null>(null)
const order = ref<{ id: number; number: string } | null>(null)
const newBelow = ref(false)
const canSend = computed(() => !!text.value.trim() || !!photo.value)

// ---- Rows with day separators ----

const dayKey = (iso: string) => new Date(iso).toDateString()
function dayLabel(iso: string) {
  const d = new Date(iso)
  const today = new Date()
  const yesterday = new Date(Date.now() - 86_400_000)
  if (d.toDateString() === today.toDateString()) return t('chat.today')
  if (d.toDateString() === yesterday.toDateString()) return t('chat.yesterday')
  return date(iso, { weekday: 'long', day: 'numeric', month: 'long' })
}
type Row = { type: 'day'; key: string; label: string } | { type: 'message'; key: string; item: ChatItem; first: boolean }
const rows = computed<Row[]>(() => {
  const out: Row[] = []
  let day = ''
  let previous: ChatItem | undefined
  for (const item of items.value) {
    const key = dayKey(item.created_at)
    if (key !== day) {
      day = key
      previous = undefined
      out.push({ type: 'day', key: `day-${key}`, label: dayLabel(item.created_at) })
    }
    // Show "Rocket team" above the first of several replies in a row.
    const first = !previous || previous.sender !== item.sender || previous.kind !== item.kind
    out.push({ type: 'message', key: item.local?.key ?? `m-${item.id}`, item, first })
    previous = item
  }
  return out
})

const clock = (iso: string) => date(iso, { hour: 'numeric', minute: '2-digit' })
const imageStyle = (image: ChatItem['image']) =>
  image?.width && image?.height ? { aspectRatio: `${image.width} / ${image.height}` } : undefined

// ---- Scrolling ----

const nearBottom = () => {
  const el = scroller.value
  return !el || el.scrollHeight - el.scrollTop - el.clientHeight < 120
}
async function scrollToBottom(smooth = false) {
  await nextTick()
  const el = scroller.value
  if (el) el.scrollTo({ top: el.scrollHeight, behavior: smooth ? 'smooth' : 'auto' })
  newBelow.value = false
}
function onScroll() {
  if (newBelow.value && nearBottom()) newBelow.value = false
}

async function showOlder() {
  const el = scroller.value
  const height = el?.scrollHeight ?? 0
  await chat.loadOlder()
  await nextTick()
  if (el) el.scrollTop = el.scrollHeight - height
}

// ---- Polling ----

const visible = () => document.visibilityState === 'visible'

async function refresh() {
  if (!online.value) return
  const wasNearBottom = nearBottom()
  const fresh = await chat.poll()
  if (!fresh.length) return
  if (wasNearBottom) scrollToBottom(true)
  else if (fresh.some((m) => m.sender === 'staff')) newBelow.value = true
  if (visible()) chat.markRead()
}

let timer: ReturnType<typeof setInterval> | undefined
function onVisibility() {
  if (visible()) {
    refresh()
    chat.markRead()
  }
}

onMounted(async () => {
  const orderId = Number(route.query.order)
  if (orderId) {
    $api<Order>(`/orders/${orderId}/`)
      .then((o) => (order.value = { id: o.id, number: o.number }))
      .catch(() => {})
  }
  await chat.load()
  await scrollToBottom()
  chat.markRead()
  // Every 3 s while the chat is on screen, every 15 s in a background tab.
  let tick = 0
  timer = setInterval(() => {
    tick += 1
    if (visible() || tick % 5 === 0) refresh()
  }, 3000)
  document.addEventListener('visibilitychange', onVisibility)
})

onBeforeUnmount(() => {
  clearInterval(timer)
  document.removeEventListener('visibilitychange', onVisibility)
  if (photoPreview.value) URL.revokeObjectURL(photoPreview.value)
})

watch(online, (now) => now && refresh())

// ---- Composer ----

function pickPhoto(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) return toast.show(t('chat.photo'), 'error')
  if (file.size > MAX_PHOTO_MB * 1024 * 1024) return toast.show(`${t('chat.photo')}: ≤ ${MAX_PHOTO_MB} MB`, 'error')
  setPhoto(file)
}
function setPhoto(file: File | null) {
  if (photoPreview.value) URL.revokeObjectURL(photoPreview.value)
  photo.value = file
  photoPreview.value = file ? URL.createObjectURL(file) : null
}
function onPaste(event: ClipboardEvent) {
  const file = [...(event.clipboardData?.files ?? [])].find((f) => f.type.startsWith('image/'))
  if (file) {
    event.preventDefault()
    setPhoto(file)
  }
}

function autosize() {
  const el = textarea.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = `${Math.min(el.scrollHeight, 144)}px`
}

function removeOrder() {
  order.value = null
  if (route.query.order) router.replace({ query: { ...route.query, order: undefined } })
}

function submit() {
  if (!canSend.value) return
  chat.send({ body: text.value, file: photo.value, orderId: order.value?.id, orderNumber: order.value?.number })
  text.value = ''
  setPhoto(null) // the message bubble keeps its own preview
  removeOrder()
  nextTick(autosize)
  scrollToBottom(true)
  textarea.value?.focus()
}

function onKeydown(event: KeyboardEvent) {
  // Enter sends on a computer; on phones Enter adds a new line and the button sends.
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing && window.matchMedia('(pointer: fine)').matches) {
    event.preventDefault()
    submit()
  }
}
</script>

<template>
  <section class="flex-1 min-h-0 flex flex-col bg-white md:card md:overflow-hidden">
    <header class="flex items-center gap-3 px-4 py-3 border-b border-line">
      <span class="relative shrink-0">
        <img src="/logo.svg" alt="" width="40" height="40" class="size-10 rounded-full bg-brand-50 p-1.5">
        <span class="absolute bottom-0 end-0 size-3 rounded-full bg-brand-500 ring-2 ring-white" />
      </span>
      <div class="min-w-0">
        <h1 class="font-extrabold leading-tight">{{ t('chat.title') }}</h1>
        <p class="text-xs text-muted truncate">{{ t('chat.subtitle') }}</p>
      </div>
    </header>

    <div class="relative flex-1 min-h-0">
      <div ref="scroller" class="h-full overflow-y-auto overscroll-contain bg-canvas px-3 md:px-5 py-4" @scroll.passive="onScroll">
        <div v-if="loading" class="space-y-3" aria-busy="true">
          <div class="h-16 w-3/4 rounded-2xl bg-white animate-pulse" />
          <div class="h-10 w-1/2 ms-auto rounded-2xl bg-brand-100 animate-pulse" />
          <div class="h-12 w-2/3 rounded-2xl bg-white animate-pulse" />
        </div>

        <EmptyState v-else-if="loadFailed" emoji="📡" :title="t('common.error')">
          <button type="button" class="btn-primary px-6" @click="chat.load()">{{ t('common.retry') }}</button>
        </EmptyState>

        <template v-else>
          <div v-if="hasOlder" class="flex justify-center mb-3">
            <button type="button" class="btn-outline h-9 text-xs" :disabled="loadingOlder" @click="showOlder">{{ t('chat.older') }}</button>
          </div>

          <div v-else class="mx-auto max-w-md text-center rounded-2xl bg-white border border-line p-4 mb-4">
            <p class="text-3xl mb-1">💬</p>
            <p class="text-sm font-semibold">{{ t('chat.welcome') }}</p>
            <p class="text-xs text-muted mt-1">{{ t('chat.hours') }}</p>
          </div>

          <ol class="flex flex-col gap-1" aria-live="polite">
            <li v-for="row in rows" :key="row.key" class="flex flex-col">
              <span v-if="row.type === 'day'" class="self-center text-[11px] font-semibold text-muted bg-white/70 rounded-full px-3 py-0.5 my-3">
                {{ row.label }}
              </span>

              <p v-else-if="row.item.kind === 'event'" class="self-center text-center text-xs text-muted bg-white rounded-full px-4 py-1.5 my-3 max-w-[90%]">
                {{ t('chat.closed') }}
              </p>

              <div
                v-else
                class="max-w-[82%] md:max-w-[70%] flex flex-col"
                :class="[row.item.sender === 'customer' ? 'self-end items-end' : 'self-start items-start', row.first ? 'mt-2' : '']"
              >
                <span v-if="row.item.sender === 'staff' && row.first" class="text-[11px] font-bold text-brand-700 mb-0.5 px-1">
                  {{ row.item.sender_name || t('chat.support') }}
                </span>
                <div
                  class="rounded-2xl px-3 py-2 text-sm shadow-[0_1px_1px_rgba(0,0,0,.04)]"
                  :class="row.item.sender === 'customer'
                    ? ['bg-brand-600 text-white rounded-ee-md', row.item.local?.status === 'failed' && 'opacity-70']
                    : 'bg-white border border-line rounded-es-md'"
                >
                  <NuxtLinkLocale
                    v-if="row.item.order"
                    :to="`/orders/${row.item.order.id}`"
                    class="inline-flex items-center gap-1 text-[11px] font-bold rounded-md px-1.5 py-0.5 mb-1"
                    :class="row.item.sender === 'customer' ? 'bg-white/20 text-white' : 'bg-brand-50 text-brand-700'"
                  >
                    <AppIcon name="package" :size="12" /> {{ t('chat.aboutOrder', { n: row.item.order.number }) }}
                  </NuxtLinkLocale>
                  <a
                    v-if="row.item.image || row.item.local?.preview"
                    :href="row.item.image?.url ?? row.item.local?.preview ?? undefined"
                    target="_blank"
                    rel="noopener"
                    class="block mb-1"
                  >
                    <img
                      :src="row.item.image?.url ?? row.item.local?.preview ?? ''"
                      :width="row.item.image?.width ?? undefined"
                      :height="row.item.image?.height ?? undefined"
                      :style="imageStyle(row.item.image)"
                      :alt="t('chat.photoMessage')"
                      loading="lazy"
                      class="rounded-xl max-h-72 w-auto max-w-full object-cover bg-black/5"
                    >
                  </a>
                  <p v-if="row.item.body" dir="auto" class="whitespace-pre-wrap break-words leading-relaxed">{{ row.item.body }}</p>
                  <p class="flex items-center justify-end gap-1 text-[10px] mt-0.5" :class="row.item.sender === 'customer' ? 'text-white/75' : 'text-muted'">
                    <span>{{ clock(row.item.created_at) }}</span>
                    <template v-if="row.item.sender === 'customer'">
                      <AppIcon v-if="chat.receipt(row.item) === 'sending'" name="clock" :size="12" :aria-label="t('chat.sending')" />
                      <AppIcon v-else-if="chat.receipt(row.item) === 'sent'" name="check" :size="13" :stroke="2.5" />
                      <AppIcon v-else-if="chat.receipt(row.item) === 'seen'" name="check-double" :size="14" :stroke="2.5" class="text-brand-200" />
                      <span class="sr-only">{{ t(`chat.${chat.receipt(row.item)}`) }}</span>
                    </template>
                  </p>
                </div>
                <div v-if="row.item.local?.status === 'failed'" class="flex items-center gap-2 mt-1 text-xs text-danger">
                  <button type="button" class="inline-flex items-center gap-1 font-bold" @click="chat.retry(row.item)">
                    <AppIcon name="alert" :size="14" /> {{ row.item.local.error || t('chat.failed') }}
                  </button>
                  <button type="button" class="p-0.5 text-muted hover:text-danger" :aria-label="t('common.delete')" @click="chat.discard(row.item)">
                    <AppIcon name="x" :size="14" />
                  </button>
                </div>
              </div>
            </li>
          </ol>
        </template>
      </div>

      <button
        v-if="newBelow"
        type="button"
        class="absolute bottom-3 inset-x-0 mx-auto w-max chip chip-active shadow-lg"
        @click="scrollToBottom(true)"
      >
        <AppIcon name="chevron-down" :size="16" /> {{ t('chat.newMessages') }}
      </button>
    </div>

    <form class="border-t border-line bg-white px-3 pt-2 pb-[max(0.5rem,env(safe-area-inset-bottom))]" @submit.prevent="submit">
      <div v-if="order || photoPreview" class="flex flex-wrap items-end gap-2 mb-2">
        <span v-if="order" class="chip h-8 text-xs bg-brand-50 border-brand-100 text-brand-700">
          <AppIcon name="package" :size="14" /> {{ t('chat.aboutOrder', { n: order.number }) }}
          <button type="button" class="-me-1 p-0.5" :aria-label="t('chat.removeOrder')" @click="removeOrder"><AppIcon name="x" :size="14" /></button>
        </span>
        <span v-if="photoPreview" class="relative">
          <img :src="photoPreview" alt="" class="h-20 rounded-xl border border-line object-cover">
          <button
            type="button"
            class="absolute -top-2 -end-2 grid place-items-center size-6 rounded-full bg-ink text-white"
            :aria-label="t('chat.removePhoto')"
            @click="setPhoto(null)"
          >
            <AppIcon name="x" :size="14" :stroke="3" />
          </button>
        </span>
      </div>
      <div class="flex items-end gap-2">
        <button
          type="button"
          class="grid place-items-center size-11 shrink-0 rounded-xl text-muted hover:bg-canvas hover:text-brand-700"
          :aria-label="t('chat.photo')"
          :title="t('chat.photo')"
          @click="fileInput?.click()"
        >
          <AppIcon name="image" :size="22" />
        </button>
        <input ref="fileInput" type="file" accept="image/*" class="hidden" @change="pickPhoto">
        <textarea
          ref="textarea"
          v-model="text"
          rows="1"
          maxlength="2000"
          dir="auto"
          :placeholder="t('chat.placeholder')"
          :aria-label="t('chat.placeholder')"
          class="field h-11 min-h-11 max-h-36 py-2.5 resize-none leading-6"
          @input="autosize"
          @keydown="onKeydown"
          @paste="onPaste"
        />
        <button type="submit" class="btn-primary size-11 shrink-0 p-0 rounded-xl" :disabled="!canSend" :aria-label="t('chat.send')">
          <AppIcon name="send-end" :size="20" />
        </button>
      </div>
    </form>
  </section>
</template>
