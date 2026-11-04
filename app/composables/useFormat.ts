export function useFormat() {
  const { locale, t } = useI18n()
  const intlLocale = computed(() => (locale.value === 'ar' ? 'ar-EG-u-nu-latn' : 'en-EG'))

  const money = (value: number) =>
    new Intl.NumberFormat(intlLocale.value, {
      style: 'currency',
      currency: 'EGP',
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(value)

  const number = (value: number) => new Intl.NumberFormat(intlLocale.value, { maximumFractionDigits: 2 }).format(value)

  /** 0.25 → "250 g", 1.5 → "1.5 kg", 3 → "3". */
  const qty = (value: number, soldByWeight: boolean) => {
    if (!soldByWeight) return number(value)
    return value < 1 ? `${number(Math.round(value * 1000))} ${t('units.g')}` : `${number(value)} ${t('units.kg')}`
  }

  const date = (iso: string, options: Intl.DateTimeFormatOptions = { day: 'numeric', month: 'short' }) =>
    new Intl.DateTimeFormat(intlLocale.value, options).format(new Date(iso))

  const time = (hhmm: string) => {
    const [h, m] = hhmm.split(':').map(Number)
    const d = new Date(2000, 0, 1, h, m)
    return new Intl.DateTimeFormat(intlLocale.value, { hour: 'numeric', minute: m ? '2-digit' : undefined }).format(d)
  }

  return { money, number, qty, date, time, intlLocale }
}
