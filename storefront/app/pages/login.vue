<script setup lang="ts">
import type { AuthTokens, User } from '#shared/types/api'

definePageMeta({ hideBottomNav: true })

const { t } = useI18n()
const route = useRoute()
const localePath = useLocalePath()
const { $api } = useNuxtApp()
const auth = useAuthStore()

useSeoMeta({ title: () => t('header.login'), robots: 'noindex' })

const step = ref<'phone' | 'code' | 'name'>('phone')
const phone = ref('')
const code = ref('')
const name = ref('')
const busy = ref(false)
const error = ref('')
const resendIn = ref(0)
const codeInput = ref<HTMLInputElement>()
let countdown: ReturnType<typeof setInterval> | undefined
let otpAbort: AbortController | undefined

const redirect = computed(() => {
  const r = route.query.redirect
  return typeof r === 'string' && r.startsWith('/') && !r.startsWith('//') ? r : localePath('/')
})
const phoneValid = computed(() => /^01[0125]\d{8}$/.test(phone.value))

onMounted(() => {
  if (auth.isLoggedIn) navigateTo(redirect.value, { replace: true })
})
onBeforeUnmount(() => {
  clearInterval(countdown)
  otpAbort?.abort()
})

// Accept Arabic-Indic digits (٠١٢…) and a +20 prefix.
const toLatinDigits = (v: string) => v.replace(/[٠-٩]/g, (d) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d))).replace(/\D/g, '')
watch(phone, (v) => {
  const digits = toLatinDigits(v)
  const next = (digits.startsWith('20') && digits.length > 11 ? `0${digits.slice(2)}` : digits).slice(0, 11)
  if (next !== v) phone.value = next
})
watch(code, (v) => {
  const next = toLatinDigits(v).slice(0, 4)
  if (next !== v) code.value = next
  else if (next.length === 4 && step.value === 'code' && !busy.value) verify()
})

function startCountdown(seconds: number) {
  resendIn.value = seconds
  clearInterval(countdown)
  countdown = setInterval(() => {
    resendIn.value -= 1
    if (resendIn.value <= 0) clearInterval(countdown)
  }, 1000)
}

// WebOTP on Android Chrome fills the code from the SMS automatically (MOB-102 for web).
// The SMS must end with a line like: @rocket.example #1234
async function listenForOtp() {
  if (!('OTPCredential' in window)) return
  otpAbort?.abort()
  otpAbort = new AbortController()
  try {
    const cred = (await navigator.credentials.get({ otp: { transport: ['sms'] }, signal: otpAbort.signal } as CredentialRequestOptions)) as
      | (Credential & { code?: string })
      | null
    if (cred?.code) code.value = cred.code
  } catch {}
}

async function sendCode() {
  error.value = ''
  if (!phoneValid.value) return (error.value = t('auth.invalidPhone'))
  busy.value = true
  try {
    const res = await $api<{ resend_in: number }>('/auth/otp/send/', { method: 'POST', body: { phone: phone.value } })
    step.value = 'code'
    code.value = ''
    startCountdown(res.resend_in ?? 60)
    listenForOtp()
    nextTick(() => codeInput.value?.focus())
  } catch (e) {
    error.value = apiErrorMessage(e, t('common.error'))
  } finally {
    busy.value = false
  }
}

async function verify() {
  busy.value = true
  error.value = ''
  try {
    const res = await $api<AuthTokens>('/auth/otp/verify/', { method: 'POST', body: { phone: phone.value, code: code.value } })
    auth.setSession(res)
    otpAbort?.abort()
    if (res.is_new) step.value = 'name'
    else finish()
  } catch (e) {
    error.value = apiErrorMessage(e, t('common.error'))
    code.value = ''
  } finally {
    busy.value = false
  }
}

async function saveName() {
  if (name.value.trim()) {
    try {
      auth.setUser(await $api<User>('/me/', { method: 'PATCH', body: { name: name.value.trim() } }))
    } catch {}
  }
  finish()
}

function finish() {
  navigateTo(redirect.value, { replace: true })
}
</script>

<template>
  <div class="max-w-md mx-auto pt-4 md:pt-10">
    <div class="card p-6">
      <img src="/logo.svg" alt="" width="56" height="56" class="size-14 mb-4">

      <form v-if="step === 'phone'" class="space-y-4" @submit.prevent="sendCode">
        <div>
          <h1 class="text-2xl font-extrabold">{{ t('auth.title') }}</h1>
          <p class="text-sm text-muted mt-1">{{ t('auth.subtitle') }}</p>
        </div>
        <label class="block">
          <span class="label">{{ t('auth.phone') }}</span>
          <input
            v-model="phone"
            type="tel"
            inputmode="numeric"
            autocomplete="tel-national"
            dir="ltr"
            class="field h-12 text-lg tracking-wider text-start"
            :placeholder="t('auth.phonePlaceholder')"
            required
          >
        </label>
        <p v-if="error" class="text-sm font-bold text-danger">{{ error }}</p>
        <button type="submit" class="btn-primary w-full h-12 text-base" :disabled="busy || !phoneValid">{{ t('auth.sendCode') }}</button>
      </form>

      <form v-else-if="step === 'code'" class="space-y-4" @submit.prevent="verify">
        <div>
          <h1 class="text-2xl font-extrabold">{{ t('auth.codeTitle') }}</h1>
          <p class="text-sm text-muted mt-1">{{ t('auth.codeSent', { phone }) }}</p>
        </div>
        <label class="block">
          <span class="sr-only">{{ t('auth.code') }}</span>
          <input
            ref="codeInput"
            v-model="code"
            type="text"
            inputmode="numeric"
            autocomplete="one-time-code"
            dir="ltr"
            maxlength="4"
            class="field h-14 text-3xl font-extrabold tracking-[0.75em] text-center"
            placeholder="••••"
          >
        </label>
        <p class="text-xs font-bold rounded-lg bg-accent-50 text-accent-700 px-3 py-2">{{ t('auth.demoHint') }}</p>
        <p v-if="error" class="text-sm font-bold text-danger">{{ error }}</p>
        <button type="submit" class="btn-primary w-full h-12 text-base" :disabled="busy || code.length < 4">{{ t('auth.verify') }}</button>
        <div class="flex items-center justify-between text-sm">
          <button type="button" class="font-bold text-brand-700" @click="step = 'phone'">{{ t('auth.changePhone') }}</button>
          <button v-if="resendIn <= 0" type="button" class="font-bold text-brand-700" :disabled="busy" @click="sendCode">{{ t('auth.resend') }}</button>
          <span v-else class="text-muted">{{ t('auth.resendIn', { s: resendIn }) }}</span>
        </div>
      </form>

      <form v-else class="space-y-4" @submit.prevent="saveName">
        <h1 class="text-2xl font-extrabold">{{ t('auth.nameTitle') }}</h1>
        <label class="block">
          <span class="label">{{ t('auth.name') }}</span>
          <input v-model="name" class="field h-12" autocomplete="name" maxlength="80">
        </label>
        <button type="submit" class="btn-primary w-full h-12 text-base">{{ t('auth.finish') }}</button>
        <button type="button" class="btn-ghost w-full" @click="finish">{{ t('auth.skip') }}</button>
      </form>
    </div>
  </div>
</template>
