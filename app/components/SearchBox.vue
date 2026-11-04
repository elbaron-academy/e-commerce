<script setup lang="ts">
import type { SearchSuggestion } from '#shared/types/api'

const props = withDefaults(defineProps<{ autofocus?: boolean; initial?: string }>(), { initial: '' })
const emit = defineEmits<{ search: [term: string] }>()

const { t } = useI18n()
const localePath = useLocalePath()
const { $api } = useNuxtApp()

const q = ref(props.initial)
const open = ref(false)
const suggestions = ref<SearchSuggestion[]>([])
const active = ref(-1)
const input = ref<HTMLInputElement>()
const listId = useId()
let timer: ReturnType<typeof setTimeout> | undefined
let seq = 0

watch(() => props.initial, (value) => (q.value = value))

watch(q, (value) => {
  clearTimeout(timer)
  active.value = -1
  const term = value.trim()
  if (term.length < 2) {
    suggestions.value = []
    return
  }
  timer = setTimeout(async () => {
    const id = ++seq
    try {
      const res = await $api<SearchSuggestion[]>('/search/autocomplete/', { query: { q: term } })
      if (id === seq) suggestions.value = res
    } catch {
      // Offline or slow network: keep typing works, suggestions just don't show.
    }
  }, 220)
})

function submit() {
  const term = q.value.trim()
  if (!term) return
  open.value = false
  input.value?.blur()
  emit('search', term)
  navigateTo({ path: localePath('/search'), query: { q: term } })
}

function go(s: SearchSuggestion) {
  open.value = false
  emit('search', s.name)
  navigateTo(localePath(s.type === 'product' ? `/product/${s.slug}` : `/category/${s.slug}`))
}

function onKey(e: KeyboardEvent) {
  const n = suggestions.value.length
  if (!n) return
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    active.value = (active.value + 1) % n
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    active.value = (active.value - 1 + n) % n
  } else if (e.key === 'Enter' && active.value >= 0) {
    e.preventDefault()
    go(suggestions.value[active.value]!)
  } else if (e.key === 'Escape') {
    open.value = false
  }
}

onMounted(() => {
  if (props.autofocus) input.value?.focus()
})
</script>

<template>
  <form role="search" class="relative" @submit.prevent="submit">
    <AppIcon name="search" :size="20" class="absolute top-1/2 -translate-y-1/2 start-3.5 text-muted pointer-events-none" />
    <input
      ref="input"
      v-model="q"
      type="search"
      enterkeyhint="search"
      autocomplete="off"
      role="combobox"
      aria-autocomplete="list"
      :aria-controls="listId"
      :aria-expanded="open && suggestions.length > 0"
      :aria-label="t('nav.search')"
      :placeholder="t('header.searchPlaceholder')"
      class="field ps-11 bg-canvas border-transparent focus:bg-white"
      @focus="open = true"
      @blur="open = false"
      @keydown="onKey"
    >
    <ul
      v-if="open && suggestions.length"
      :id="listId"
      role="listbox"
      class="absolute z-40 inset-x-0 top-full mt-2 card shadow-xl shadow-black/5 p-1.5 max-h-96 overflow-auto"
    >
      <li v-for="(s, i) in suggestions" :key="s.type + s.slug" role="option" :aria-selected="i === active">
        <button
          type="button"
          class="w-full flex items-center gap-3 rounded-xl px-2.5 py-2 text-start hover:bg-canvas"
          :class="i === active && 'bg-canvas'"
          @mousedown.prevent="go(s)"
        >
          <span class="text-2xl leading-none">{{ s.emoji }}</span>
          <span class="min-w-0">
            <span class="block text-sm font-semibold truncate">{{ s.name }}</span>
            <span class="block text-xs text-muted truncate">{{ s.type === 'category' ? t('search.inCategory') : s.subtitle }}</span>
          </span>
        </button>
      </li>
    </ul>
  </form>
</template>
