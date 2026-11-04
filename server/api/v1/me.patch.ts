import type { User } from '#shared/types/api'

export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const body = await readBody<Partial<User>>(event)
  const next: User = {
    ...user,
    name: typeof body.name === 'string' ? body.name.trim().slice(0, 80) : user.name,
    email: typeof body.email === 'string' ? body.email.trim().slice(0, 120) : user.email,
    language: body.language === 'en' || body.language === 'ar' ? body.language : user.language,
  }
  await saveUser(next)
  return next
})
