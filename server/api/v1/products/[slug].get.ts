export default defineEventHandler((event) => {
  const product = findProduct(getRouterParam(event, 'slug') || '')
  if (!product) throw createError({ statusCode: 404, data: { detail: 'Product not found.' } })
  return serializeProductDetail(product, getLang(event))
})
