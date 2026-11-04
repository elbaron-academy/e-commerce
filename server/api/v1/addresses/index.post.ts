import type { Address, AddressInput } from '#shared/types/api'
import { ZONES } from '../../../utils/catalog-data'

export default defineEventHandler(async (event) => {
  const user = await requireUser(event)
  const body = await readBody<Partial<AddressInput>>(event)
  const zone = ZONES.find((z) => z.id === body.zone)
  const required = { zone, area: body.area?.trim(), street: body.street?.trim(), building: body.building?.trim() }
  const missing = Object.entries(required).filter(([, value]) => !value).map(([key]) => key)
  if (missing.length) throw createError({ statusCode: 400, data: { detail: 'Please complete the address.', fields: missing } })

  const list = await listAddresses(user.id)
  const isDefault = body.is_default || list.length === 0
  const address: Address = {
    id: Date.now(),
    label: body.label?.trim() || '',
    zone: zone!.id,
    zone_name: tr(zone!.name, getLang(event)),
    area: required.area!,
    street: required.street!,
    building: required.building!,
    floor: body.floor?.trim() || '',
    apartment: body.apartment?.trim() || '',
    notes: body.notes?.trim() || '',
    lat: typeof body.lat === 'number' ? body.lat : null,
    lng: typeof body.lng === 'number' ? body.lng : null,
    is_default: isDefault,
  }
  // Only one default address (BE-405)
  const next = [...list.map((a) => ({ ...a, is_default: isDefault ? false : a.is_default })), address]
  await saveAddresses(user.id, next)
  setResponseStatus(event, 201)
  return address
})
