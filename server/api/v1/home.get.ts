import type { HomeData } from '#shared/types/api'
import { BANNERS, PRODUCTS, type L, type RawProduct } from '../../utils/catalog-data'

export default defineEventHandler((event): HomeData => {
  const lang = getLang(event)
  const pick = (filter: (p: RawProduct) => boolean) =>
    sortProducts(PRODUCTS.filter(filter), 'recommended').slice(0, 12).map((p) => serializeProduct(p, lang))
  const section = (key: string, title: L, link: string, filter: (p: RawProduct) => boolean) => ({
    key, title: tr(title, lang), link, products: pick(filter),
  })

  return {
    banners: BANNERS.map((b) => ({ id: b.id, tone: b.tone, emoji: b.emoji, link: b.link, title: tr(b.title, lang), subtitle: tr(b.subtitle, lang), cta: tr(b.cta, lang) })),
    sections: [
      section('offers', ['عروض الأسبوع', 'Deals of the week'], '/search?tag=offer', (p) => p.variants.some((v) => v.sale)),
      section('best', ['الأكثر مبيعًا', 'Best sellers'], '/search?tag=best', (p) => p.tags.includes('best')),
      section('fresh', ['خضار وفاكهة طازة', 'Fresh produce'], '/category/fruits-vegetables', (p) => p.cat === 'fruits-vegetables'),
      section('dairy', ['ألبان وبيض', 'Dairy & eggs'], '/category/dairy-eggs', (p) => p.cat === 'dairy-eggs'),
      section('new', ['وصل حديثًا', 'New arrivals'], '/search?tag=new', (p) => p.tags.includes('new')),
    ],
  }
})
