<script setup lang="ts">
import type { Address, AddressInput, DeliveryInfo } from '#shared/types/api'

const emit = defineEmits<{ saved: [address: Address]; cancel: [] }>()
const { t } = useI18n()
const { $api } = useNuxtApp()
const { money } = useFormat()

const { data: info } = useApiFetch<DeliveryInfo>('/delivery/info/', { key: 'delivery-info' })

const form = reactive<AddressInput>({
  label: '',
  zone: 'cairo',
  area: '',
  street: '',
  building: '',
  floor: '',
  apartment: '',
  notes: '',
  lat: null,
  lng: null,
})
const saving = ref(false)
const error = ref('')
const locating = ref<'idle' | 'busy' | 'done' | 'failed'>('idle')

// TODO(FE-402): replace with a map picker; for now we store the GPS position.
function locate() {
  if (!('geolocation' in navigator)) {
    locating.value = 'failed'
    return
  }
  locating.value = 'busy'
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      form.lat = Number(pos.coords.latitude.toFixed(6))
      form.lng = Number(pos.coords.longitude.toFixed(6))
      locating.value = 'done'
    },
    () => (locating.value = 'failed'),
    { enableHighAccuracy: true, timeout: 10_000 },
  )
}

async function save() {
  saving.value = true
  error.value = ''
  try {
    emit('saved', await $api<Address>('/addresses/', { method: 'POST', body: form }))
  } catch (e) {
    error.value = apiErrorMessage(e, t('common.error'))
  } finally {
    saving.value = false
  }
}

const locateLabel = computed(
  () => ({ idle: t('address.useLocation'), busy: t('address.locating'), done: t('address.located'), failed: t('address.locationFailed') })[locating.value],
)
</script>

<template>
  <form class="space-y-4" @submit.prevent="save">
    <button type="button" class="btn-outline w-full" :class="locating === 'done' && 'border-brand-300 bg-brand-50 text-brand-700'" :disabled="locating === 'busy'" @click="locate">
      <AppIcon :name="locating === 'done' ? 'check' : 'map-pin'" :size="18" />
      {{ locateLabel }}
    </button>

    <div class="grid grid-cols-6 gap-3">
      <label class="col-span-6 sm:col-span-3">
        <span class="label">{{ t('address.zone') }}</span>
        <select v-model="form.zone" class="field">
          <option v-for="z in info?.zones" :key="z.id" :value="z.id">{{ z.name }} · {{ t('address.deliveryFee', { amount: money(z.fee) }) }}</option>
        </select>
      </label>
      <label class="col-span-6 sm:col-span-3">
        <span class="label">{{ t('address.area') }}</span>
        <input v-model="form.area" required class="field" autocomplete="address-level2">
      </label>
      <label class="col-span-6">
        <span class="label">{{ t('address.street') }}</span>
        <input v-model="form.street" required class="field" autocomplete="address-line1">
      </label>
      <label class="col-span-2">
        <span class="label">{{ t('address.building') }}</span>
        <input v-model="form.building" required class="field">
      </label>
      <label class="col-span-2">
        <span class="label">{{ t('address.floor') }}</span>
        <input v-model="form.floor" class="field" inputmode="numeric">
      </label>
      <label class="col-span-2">
        <span class="label">{{ t('address.apartment') }}</span>
        <input v-model="form.apartment" class="field">
      </label>
      <label class="col-span-6 sm:col-span-3">
        <span class="label">{{ t('address.label') }} <span class="text-muted font-normal">({{ t('common.optional') }})</span></span>
        <input v-model="form.label" class="field" :placeholder="t('address.labelPlaceholder')">
      </label>
      <label class="col-span-6 sm:col-span-3">
        <span class="label">{{ t('address.notes') }} <span class="text-muted font-normal">({{ t('common.optional') }})</span></span>
        <input v-model="form.notes" class="field">
      </label>
    </div>

    <p v-if="error" class="text-sm font-semibold text-danger">{{ error }}</p>

    <div class="flex gap-2">
      <button type="submit" class="btn-primary flex-1" :disabled="saving">{{ t('address.save') }}</button>
      <button type="button" class="btn-outline" @click="emit('cancel')">{{ t('common.cancel') }}</button>
    </div>
  </form>
</template>
