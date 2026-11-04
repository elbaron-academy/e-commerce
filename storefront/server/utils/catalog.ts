import type { H3Event } from 'h3'
import type { CategoryNode, Lang, Paginated, ProductDetail, ProductSummary, SearchSuggestion, Variant } from '#shared/types/api'
import { normalizeText, stripArticle } from '#shared/utils/text'
import { CATEGORIES, PRODUCTS, type L, type RawProduct, type RawVariant } from './catalog-data'

export function getLang(event: H3Event): Lang {
  const q = getQuery(event).lang
  if (q === 'en' || q === 'ar') return q
  return (getHeader(event, 'accept-language') || '').toLowerCase().startsWith('en') ? 'en' : 'ar'
}

export const tr = (text: L, lang: Lang) => (lang === 'ar' ? text[0] : text[1])

const categoryBySlug = new Map(CATEGORIES.map((c) => [c.slug, c]))
const productBySlug = new Map(PRODUCTS.map((p) => [p.slug, p]))

export const skuOf = (p: RawProduct, index: number) => `RK-${String(p.id).padStart(4, '0')}-${index + 1}`

const skuIndex = new Map<string, { product: RawProduct; variant: RawVariant; index: number }>()
for (const p of PRODUCTS) p.variants.forEach((variant, index) => skuIndex.set(skuOf(p, index), { product: p, variant, index }))

export const findSku = (sku: string) => skuIndex.get(sku)
export const findProduct = (slug: string) => productBySlug.get(slug)
export const findCategory = (slug: string) => categoryBySlug.get(slug)

const MAX_UNITS = 20
const MAX_KG = 5

function variantMax(p: RawProduct, v: RawVariant) {
  return Math.max(0, Math.min(v.stock, p.weight ? MAX_KG : MAX_UNITS))
}

function saleEndsAt(p: RawProduct) {
  const d = new Date(Date.now() + ((p.id % 5) + 2) * 86_400_000)
  return d.toISOString().slice(0, 10)
}

export function serializeProduct(p: RawProduct, lang: Lang): ProductSummary {
  const cat = categoryBySlug.get(p.cat)!
  const sub = cat.subs.find(([slug]) => slug === p.sub)
  const variants: Variant[] = p.variants.map((v, i) => ({
    sku: skuOf(p, i),
    label: tr(v.label, lang),
    price: v.price,
    sale_price: v.sale ?? null,
    in_stock: v.stock > 0,
    stock: v.stock,
    max_qty: variantMax(p, v),
  }))
  const def = variants.find((v) => v.in_stock) ?? variants[0]!
  const onSale = variants.some((v) => v.sale_price !== null)
  const weight = !!p.weight
  return {
    id: p.id,
    slug: p.slug,
    name: tr(p.name, lang),
    brand: tr(p.brand ?? cat.brand, lang),
    image: null,
    emoji: p.emoji,
    color: cat.color,
    category: { slug: cat.slug, name: tr(cat.name, lang) },
    subcategory: sub ? { slug: sub[0], name: tr(sub[1], lang) } : null,
    unit_label: def.label,
    sold_by_weight: weight,
    qty_step: weight ? 0.25 : 1,
    min_qty: weight ? 0.5 : 1,
    max_qty: def.max_qty,
    price: def.price,
    sale_price: def.sale_price,
    discount_percent: def.sale_price ? Math.round((1 - def.sale_price / def.price) * 100) : 0,
    sale_ends_at: onSale ? saleEndsAt(p) : null,
    in_stock: variants.some((v) => v.in_stock),
    default_sku: def.sku,
    variants,
    rating: 4 + ((p.id * 7) % 10) / 10,
    tags: [...p.tags, ...(onSale ? ['offer'] : [])],
  }
}

export function serializeProductDetail(p: RawProduct, lang: Lang): ProductDetail {
  const cat = categoryBySlug.get(p.cat)!
  return { ...serializeProduct(p, lang), description: tr(cat.description, lang), images: [] }
}

export function categoryTree(lang: Lang): CategoryNode[] {
  return CATEGORIES.map((c) => ({
    id: c.id,
    slug: c.slug,
    name: tr(c.name, lang),
    emoji: c.emoji,
    color: c.color,
    image: null,
    product_count: PRODUCTS.filter((p) => p.cat === c.slug).length,
    children: c.subs.map(([slug, name], i) => ({
      id: c.id * 100 + i + 1,
      slug,
      name: tr(name, lang),
      emoji: c.emoji,
      color: c.color,
      image: null,
      product_count: PRODUCTS.filter((p) => p.cat === c.slug && p.sub === slug).length,
      children: [],
    })),
  }))
}

// ---- Sorting & pagination ----

const effectivePrice = (p: RawProduct) => {
  const v = p.variants.find((x) => x.stock > 0) ?? p.variants[0]!
  return v.sale ?? v.price
}
const bestDiscount = (p: RawProduct) => Math.max(...p.variants.map((v) => (v.sale ? 1 - v.sale / v.price : 0)))
const soldCount = (p: RawProduct) => (p.tags.includes('best') ? 1000 : 0) + ((p.id * 37) % 300)
const inStock = (p: RawProduct) => (p.variants.some((v) => v.stock > 0) ? 1 : 0)

export function sortProducts(list: RawProduct[], sort: string): RawProduct[] {
  const items = [...list]
  switch (sort) {
    case 'price_asc':
      return items.sort((a, b) => effectivePrice(a) - effectivePrice(b))
    case 'price_desc':
      return items.sort((a, b) => effectivePrice(b) - effectivePrice(a))
    case 'newest':
      return items.sort((a, b) => b.id - a.id)
    case 'discount':
      return items.sort((a, b) => bestDiscount(b) - bestDiscount(a))
    case 'best':
      return items.sort((a, b) => soldCount(b) - soldCount(a))
    default:
      return items.sort((a, b) => inStock(b) - inStock(a) || soldCount(b) - soldCount(a))
  }
}

export function paginate<T>(items: T[], pageParam: unknown, pageSizeParam: unknown, max = 48): Paginated<T> {
  const pageSize = Math.min(max, Math.max(1, Number(pageSizeParam) || 24))
  const page = Math.max(1, Number(pageParam) || 1)
  const start = (page - 1) * pageSize
  return {
    count: items.length,
    next: start + pageSize < items.length ? page + 1 : null,
    previous: page > 1 ? page - 1 : null,
    results: items.slice(start, start + pageSize),
  }
}

// ---- Search (Arabic-aware, typo tolerant) ----

function wordsOf(text: string) {
  const words = normalizeText(text).split(' ').filter(Boolean)
  return [...new Set([...words, ...words.map(stripArticle)])]
}

const productWords = new Map<number, { name: string[]; all: string[] }>(
  PRODUCTS.map((p) => {
    const cat = categoryBySlug.get(p.cat)!
    const sub = cat.subs.find(([slug]) => slug === p.sub)
    const name = wordsOf(p.name.join(' '))
    const other = wordsOf([...(p.brand ?? cat.brand), ...cat.name, ...(sub ? sub[1] : []), p.slug.replace(/-/g, ' ')].join(' '))
    return [p.id, { name, all: [...name, ...other] }]
  }),
)

function levenshtein(a: string, b: string): number {
  if (a === b) return 0
  const dp = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    let prev = dp[0]!
    dp[0] = i
    for (let j = 1; j <= b.length; j++) {
      const tmp = dp[j]!
      dp[j] = Math.min(dp[j]! + 1, dp[j - 1]! + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1))
      prev = tmp
    }
  }
  return dp[b.length]!
}

const exactHit = (words: string[], token: string) => words.some((w) => w.startsWith(token) || (token.length >= 3 && w.includes(token)))
const fuzzyHit = (words: string[], token: string) =>
  token.length >= 3 && words.some((w) => Math.abs(w.length - token.length) <= 2 && levenshtein(w, token) <= (token.length >= 6 ? 2 : 1))

export function searchProducts(query: string): RawProduct[] {
  const tokens = normalizeText(query).split(' ').filter(Boolean).map(stripArticle)
  if (!tokens.length) return []
  const score = (p: RawProduct, fuzzy: boolean) => {
    const w = productWords.get(p.id)!
    const hit = fuzzy ? (words: string[], t: string) => exactHit(words, t) || fuzzyHit(words, t) : exactHit
    if (!tokens.every((t) => hit(w.all, t))) return 0
    return 1 + tokens.filter((t) => hit(w.name, t)).length
  }
  for (const fuzzy of [false, true]) {
    const ranked = PRODUCTS.map((p) => ({ p, s: score(p, fuzzy) }))
      .filter((x) => x.s > 0)
      .sort((a, b) => b.s - a.s || inStock(b.p) - inStock(a.p) || soldCount(b.p) - soldCount(a.p))
    if (ranked.length) return ranked.map((x) => x.p)
  }
  return []
}

export function autocomplete(query: string, lang: Lang): SearchSuggestion[] {
  const products = searchProducts(query).slice(0, 6)
  const tokens = normalizeText(query).split(' ').filter(Boolean).map(stripArticle)
  const categories = CATEGORIES.filter((c) => tokens.every((t) => exactHit(wordsOf(c.name.join(' ')), t))).slice(0, 2)
  return [
    ...categories.map<SearchSuggestion>((c) => ({ type: 'category', slug: c.slug, name: tr(c.name, lang), emoji: c.emoji, subtitle: '' })),
    ...products.map<SearchSuggestion>((p) => {
      const s = serializeProduct(p, lang)
      return { type: 'product', slug: s.slug, name: s.name, emoji: s.emoji, subtitle: `${s.unit_label} · ${s.category.name}` }
    }),
  ]
}
