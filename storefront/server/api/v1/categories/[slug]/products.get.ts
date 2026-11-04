import { PRODUCTS } from '../../../../utils/catalog-data'

export default defineEventHandler((event) => {
  const slug = getRouterParam(event, 'slug') || ''
  if (!findCategory(slug)) throw createError({ statusCode: 404, data: { detail: 'Category not found.' } })
  const { sub, sort, page, page_size } = getQuery(event)
  const lang = getLang(event)
  const list = PRODUCTS.filter((p) => p.cat === slug && (!sub || p.sub === sub))
  return paginate(sortProducts(list, String(sort || 'recommended')).map((p) => serializeProduct(p, lang)), page, page_size)
})
