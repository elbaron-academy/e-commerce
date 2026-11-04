import type { AuthTokens } from '#shared/types/api'

export default defineEventHandler(async (event): Promise<AuthTokens> => {
  const { phone, code } = await readBody<{ phone?: string; code?: string }>(event)
  if (!phone || !PHONE_RE.test(phone) || code !== MOCK_OTP) {
    throw createError({ statusCode: 400, data: { detail: 'The code is incorrect or expired.', field: 'code' } })
  }
  const { user, isNew } = await ensureUser(phone)
  return { access: tokenFor(phone), refresh: `${tokenFor(phone)}.refresh`, user, is_new: isNew }
})
