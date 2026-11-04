import { PRODUCTS } from '../../../utils/catalog-data'

// GET /search/?q=&tag=&sort=&page=
export default defineEventHandler((event) => {
  const { q, tag, sort, page, page_size } = getQuery(event)
  const lang = getLang(event)
  const query = String(q || '').trim()
  let list = query ? searchProducts(query) : []
  if (!query && tag) {
    list = PRODUCTS.filter((p) => (tag === 'offer' ? p.variants.some((v) => v.sale) : p.tags.includes(String(tag))))
  }
  if (sort && sort !== 'recommended') list = sortProducts(list, String(sort))
  return paginate(list.map((p) => serializeProduct(p, lang)), page, page_size)
})
