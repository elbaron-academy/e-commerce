import type { ChatMessage } from '#shared/types/api'

const MAX_PHOTO_BYTES = 3 * 1024 * 1024 // kept small: the mock stores photos inline

export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const lang = getLang(event)
  let body = ''
  let orderId: number | null = null
  let image: ChatMessage['image'] = null

  if ((getHeader(event, 'content-type') || '').includes('multipart/form-data')) {
    for (const part of (await readMultipartFormData(event)) ?? []) {
      if (part.name === 'body') body = part.data.toString('utf8')
      if (part.name === 'order') orderId = Number(part.data.toString('utf8')) || null
      if (part.name === 'image' && part.data.length) {
        if (!part.type?.startsWith('image/')) {
          throw createError({ statusCode: 400, data: { detail: lang === 'ar' ? 'ابعت صورة JPG أو PNG.' : 'Send a JPG or PNG photo.', code: 'invalid_image', field: 'image' } })
        }
        if (part.data.length > MAX_PHOTO_BYTES) {
          throw createError({ statusCode: 400, data: { detail: lang === 'ar' ? 'الصورة كبيرة أوي.' : 'The photo is too large.', code: 'image_too_large', field: 'image' } })
        }
        image = { url: `data:${part.type};base64,${part.data.toString('base64')}`, width: null, height: null }
      }
    }
  } else {
    const json = (await readBody<{ body?: string; order?: number | null }>(event)) ?? {}
    body = json.body ?? ''
    orderId = json.order ?? null
  }

  body = body.trim()
  if (!body && !image) {
    throw createError({ statusCode: 400, data: { detail: lang === 'ar' ? 'اكتب رسالة أو ابعت صورة.' : 'Write a message or send a photo.', code: 'invalid', field: 'body' } })
  }
  if (body.length > 2000) {
    throw createError({ statusCode: 400, data: { detail: 'Ensure this field has no more than 2000 characters.', code: 'invalid', field: 'body' } })
  }

  let order: ChatMessage['order'] = null
  if (orderId) {
    const found = (await listOrders(user.id)).find((o) => o.id === orderId)
    if (!found) throw createError({ statusCode: 400, data: { detail: 'Order not found.', code: 'error', field: 'order' } })
    order = { id: found.id, number: found.number }
  }

  setResponseStatus(event, 201)
  return addCustomerMessage(user.id, lang, { body, image, order })
})
