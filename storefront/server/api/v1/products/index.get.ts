import { PRODUCTS } from '../../../utils/catalog-data'

// GET /products/?category=&tag=&exclude=&sort=&page=&page_size=
export default defineEventHandler((event) => {
  const { category, tag, exclude, sort, page, page_size } = getQuery(event)
  const lang = getLang(event)
  const list = PRODUCTS.filter((p) => {
    if (category && p.cat !== category) return false
    if (exclude && p.slug === exclude) return false
    if (tag === 'offer') return p.variants.some((v) => v.sale)
    if (tag) return p.tags.includes(String(tag))
    return true
  })
  return paginate(sortProducts(list, String(sort || 'recommended')).map((p) => serializeProduct(p, lang)), page, page_size)
})
