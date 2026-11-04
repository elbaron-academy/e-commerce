import type { DeliveryInfo } from '#shared/types/api'
import { STORE_RULES, ZONES } from '../../../utils/catalog-data'

export default defineEventHandler((event): DeliveryInfo => {
  const lang = getLang(event)
  return {
    zones: ZONES.map((z) => ({ id: z.id, name: tr(z.name, lang), fee: z.fee })),
    free_delivery_threshold: STORE_RULES.freeDeliveryThreshold,
    min_order: STORE_RULES.minOrder,
    pickup: { name: tr(STORE_RULES.pickup.name, lang), address: tr(STORE_RULES.pickup.address, lang), hours: tr(STORE_RULES.pickup.hours, lang) },
  }
})
