<script setup lang="ts">
import type { Address, User } from '#shared/types/api'

definePageMeta({ middleware: 'auth' })

const { t } = useI18n()
const { $api } = useNuxtApp()
const auth = useAuthStore()
const toast = useToast()
const localePath = useLocalePath()
const pwa = usePWA()

useSeoMeta({ title: () => t('account.title'), robots: 'noindex' })

const { data: me } = useApiFetch<User>('/me/', { key: 'me' })
const { data: addresses, refresh: refreshAddresses } = useApiFetch<Address[]>('/addresses/', { key: 'addresses' })

const form = reactive({ name: '', email: '' })
const saving = ref(false)
const addingAddress = ref(false)

watch(me, (user) => {
  if (!user) return
  form.name = user.name
  form.email = user.email
  auth.setUser(user)
}, { immediate: true })

const initial = computed(() => (auth.user?.name || auth.user?.phone || '?').trim().charAt(0).toUpperCase())

async function saveProfile() {
  saving.value = true
  try {
    auth.setUser(await $api<User>('/me/', { method: 'PATCH', body: form }))
    toast.show(t('account.saved'), 'success')
  } catch (e) {
    toast.show(apiErrorMessage(e, t('common.error')), 'error')
  } finally {
    saving.value = false
  }
}

async function deleteAddress(id: number) {
  await $api(`/addresses/${id}/`, { method: 'DELETE' }).catch(() => {})
  refreshAddresses()
}

function onAddressSaved() {
  addingAddress.value = false
  refreshAddresses()
}

function logout() {
  auth.logout()
  navigateTo(localePath('/'))
}
</script>

<template>
  <div class="max-w-2xl mx-auto space-y-4">
    <section class="card p-4 flex items-center gap-4">
      <span class="size-14 rounded-full bg-brand-600 text-white grid place-items-center text-xl font-extrabold">{{ initial }}</span>
      <div class="min-w-0">
        <h1 class="text-lg font-extrabold truncate">{{ auth.user?.name || t('account.guest') }}</h1>
        <p class="text-sm text-muted" dir="ltr">{{ auth.user?.phone }}</p>
      </div>
      <NuxtLinkLocale to="/orders" class="btn-outline ms-auto h-10">
        <AppIcon name="package" :size="18" /> {{ t('account.orders') }}
      </NuxtLinkLocale>
    </section>

    <section v-if="pwa?.showInstallPrompt && !pwa?.isPWAInstalled" class="card p-4 flex items-center gap-3 bg-brand-50 border-brand-100">
      <img src="/pwa-192x192.png" alt="" width="44" height="44" class="size-11 rounded-xl">
      <div class="flex-1 min-w-0">
        <p class="font-extrabold text-sm">{{ t('account.installApp') }}</p>
        <p class="text-xs text-muted">{{ t('account.installHint') }}</p>
      </div>
      <button type="button" class="btn-primary h-10" @click="pwa.install()"><AppIcon name="download" :size="16" /> {{ t('pwa.install') }}</button>
    </section>

    <section class="card p-4">
      <h2 class="font-extrabold mb-3">{{ t('account.profile') }}</h2>
      <form class="grid sm:grid-cols-2 gap-3" @submit.prevent="saveProfile">
        <label>
          <span class="label">{{ t('account.name') }}</span>
          <input v-model="form.name" class="field" autocomplete="name" maxlength="80">
        </label>
        <label>
          <span class="label">{{ t('account.email') }} <span class="text-muted font-normal">({{ t('common.optional') }})</span></span>
          <input v-model="form.email" type="email" class="field" autocomplete="email" dir="ltr">
        </label>
        <div class="sm:col-span-2">
          <button type="submit" class="btn-primary px-6" :disabled="saving">{{ t('common.save') }}</button>
        </div>
      </form>
    </section>

    <section class="card p-4">
      <h2 class="font-extrabold mb-3">{{ t('account.addresses') }}</h2>
      <ul v-if="addresses?.length" class="space-y-2 mb-3">
        <li v-for="a in addresses" :key="a.id" class="flex items-start gap-3 rounded-xl bg-canvas p-3">
          <AppIcon name="map-pin" :size="20" class="text-brand-700 mt-0.5" />
          <div class="text-sm min-w-0 flex-1">
            <p class="font-bold">{{ a.label || a.area }} <span v-if="a.is_default" class="text-xs text-brand-700">· {{ t('address.default') }}</span></p>
            <p class="text-muted truncate">{{ [a.street, a.building, a.area, a.zone_name].filter(Boolean).join('، ') }}</p>
          </div>
          <button type="button" class="p-1 text-muted hover:text-danger" :aria-label="t('common.delete')" @click="deleteAddress(a.id)">
            <AppIcon name="trash" :size="18" />
          </button>
        </li>
      </ul>
      <AddressForm v-if="addingAddress" @saved="onAddressSaved" @cancel="addingAddress = false" />
      <button v-else type="button" class="btn-outline" @click="addingAddress = true">
        <AppIcon name="plus" :size="18" /> {{ t('checkout.addAddress') }}
      </button>
    </section>

    <section class="card p-4 flex items-center justify-between">
      <span class="font-extrabold">{{ t('account.language') }}</span>
      <LangSwitch />
    </section>

    <button type="button" class="btn-outline w-full text-danger" @click="logout">
      <AppIcon name="logout" :size="18" /> {{ t('account.logout') }}
    </button>
  </div>
</template>
