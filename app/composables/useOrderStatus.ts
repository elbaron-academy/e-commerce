import type { DeliveryMethod, OrderStatus } from '#shared/types/api'

export function useOrderStatus() {
  const { t } = useI18n()
  const label = (status: OrderStatus, method: DeliveryMethod) =>
    t(`orders.status.${status === 'delivered' && method === 'pickup' ? 'collected' : status}`)
  const tone = (status: OrderStatus) =>
    ({
      pending_payment: 'bg-amber-100 text-amber-800',
      placed: 'bg-sky-100 text-sky-800',
      confirmed: 'bg-sky-100 text-sky-800',
      preparing: 'bg-violet-100 text-violet-800',
      out_for_delivery: 'bg-accent-100 text-accent-700',
      ready_for_pickup: 'bg-accent-100 text-accent-700',
      delivered: 'bg-brand-100 text-brand-800',
      cancelled: 'bg-danger-50 text-danger',
    })[status]
  return { label, tone }
}
