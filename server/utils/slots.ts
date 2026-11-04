import type { Slot, SlotDay } from '#shared/types/api'

const WINDOWS: [number, number][] = [[9, 11], [11, 13], [13, 15], [15, 17], [17, 19], [19, 21], [21, 23]]
const pad = (n: number) => String(n).padStart(2, '0')

function cairoNow() {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', { timeZone: 'Africa/Cairo', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', hourCycle: 'h23' })
      .formatToParts(new Date())
      .map((p) => [p.type, p.value]),
  )
  return { date: `${parts.year}-${parts.month}-${parts.day}`, hour: Number(parts.hour) }
}

function addDays(date: string, days: number) {
  const d = new Date(`${date}T00:00:00Z`)
  d.setUTCDate(d.getUTCDate() + days)
  return d.toISOString().slice(0, 10)
}

/** Delivery windows for today and the next two days, in Cairo time. */
export function deliverySlots(): SlotDay[] {
  const now = cairoNow()
  const days: SlotDay[] = []
  for (let i = 0; i < 3; i++) {
    const date = addDays(now.date, i)
    const slots: Slot[] = []
    if (i === 0 && now.hour >= 8 && now.hour < 22) {
      slots.push({ id: 'express', start: '', end: '', available: true, express: true })
    }
    for (const [start, end] of WINDOWS) {
      const full = (i === 1 && start === 17) || (i === 2 && start === 11)
      const tooSoon = i === 0 && start < now.hour + 2
      slots.push({ id: `${date}_${pad(start)}`, start: `${pad(start)}:00`, end: `${pad(end)}:00`, available: !full && !tooSoon, express: false })
    }
    if (slots.some((s) => s.available)) days.push({ date, slots })
  }
  return days
}

export function findSlot(id: string) {
  for (const day of deliverySlots()) {
    const slot = day.slots.find((s) => s.id === id)
    if (slot) return { date: day.date, ...slot }
  }
  return null
}
