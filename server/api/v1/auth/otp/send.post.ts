// Mock OTP: any valid Egyptian mobile number, the code is always 1234.
const attempts = new Map<string, number[]>()

export default defineEventHandler(async (event) => {
  const { phone } = await readBody<{ phone?: string }>(event)
  if (!phone || !PHONE_RE.test(phone)) {
    throw createError({ statusCode: 400, data: { detail: 'Enter a valid Egyptian mobile number.', field: 'phone' } })
  }
  const hourAgo = Date.now() - 3_600_000
  const recent = (attempts.get(phone) ?? []).filter((t) => t > hourAgo)
  if (recent.length >= 5) {
    throw createError({ statusCode: 429, data: { detail: 'Too many attempts. Try again in an hour.' } })
  }
  attempts.set(phone, [...recent, Date.now()])
  return { sent: true, expires_in: 120, resend_in: 60 }
})
