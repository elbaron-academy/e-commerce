import type { H3Event } from 'h3'
import type { Address, Order, OrderStatus, User } from '#shared/types/api'

// Simple key-value storage for the mock API (memory or .data/kv in dev).
const db = () => useStorage('data')

export const PHONE_RE = /^01[0125]\d{8}$/
export const MOCK_OTP = '1234'

export function tokenFor(phone: string) {
  return `mock.${Buffer.from(phone).toString('base64url')}`
}

export async function ensureUser(phone: string): Promise<{ user: User; isNew: boolean }> {
  const key = `mock:users:${phone}`
  const existing = await db().getItem<User>(key)
  if (existing) return { user: existing, isNew: !existing.name }
  const user: User = { id: Number(phone.slice(-8)), phone, name: '', email: '', language: 'ar' }
  await db().setItem(key, user)
  return { user, isNew: true }
}

export async function saveUser(user: User) {
  await db().setItem(`mock:users:${user.phone}`, user)
}

export async function requireUser(event: H3Event): Promise<User> {
  const match = (getHeader(event, 'authorization') || '').match(/^Bearer mock\.([\w-]+)$/)
  const phone = match ? Buffer.from(match[1]!, 'base64url').toString() : ''
  if (!PHONE_RE.test(phone)) {
    throw createError({ statusCode: 401, statusMessage: 'Unauthorized', data: { detail: 'Authentication credentials were not provided.' } })
  }
  return (await ensureUser(phone)).user
}

// ---- Addresses ----

export async function listAddresses(userId: number) {
  return (await db().getItem<Address[]>(`mock:addresses:${userId}`)) ?? []
}

export async function saveAddresses(userId: number, list: Address[]) {
  await db().setItem(`mock:addresses:${userId}`, list)
}

// ---- Orders ----

/** What we store. Status and timeline are derived on read to simulate progress. */
export interface StoredOrder extends Omit<Order, 'status' | 'timeline'> {
  state: 'pending_payment' | 'active' | 'cancelled'
  placed_at: string | null
}

export async function listOrders(userId: number) {
  return (await db().getItem<StoredOrder[]>(`mock:orders:${userId}`)) ?? []
}

export async function saveOrders(userId: number, list: StoredOrder[]) {
  await db().setItem(`mock:orders:${userId}`, list)
}

export async function nextOrderId() {
  const current = (await db().getItem<number>('mock:order_seq')) ?? 1000
  await db().setItem('mock:order_seq', current + 1)
  return current + 1
}

// Minutes after placing when each step is reached (demo speed).
const STEP_MINUTES = [0, 1, 3, 6, 10]

export function presentOrder(o: StoredOrder): Order {
  const { state, placed_at, ...rest } = o
  const steps: OrderStatus[] =
    o.method === 'pickup'
      ? ['placed', 'confirmed', 'preparing', 'ready_for_pickup', 'delivered']
      : ['placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered']

  if (state !== 'active' || !placed_at) {
    return {
      ...rest,
      status: state === 'cancelled' ? 'cancelled' : 'pending_payment',
      timeline: steps.map((status) => ({ status, at: null, done: false })),
    }
  }

  const start = new Date(placed_at).getTime()
  const elapsed = (Date.now() - start) / 60_000
  let index = 0
  STEP_MINUTES.forEach((m, i) => {
    if (elapsed >= m) index = i
  })
  return {
    ...rest,
    status: steps[index]!,
    timeline: steps.map((status, i) => ({
      status,
      done: i <= index,
      at: i <= index ? new Date(start + STEP_MINUTES[i]! * 60_000).toISOString() : null,
    })),
  }
}
