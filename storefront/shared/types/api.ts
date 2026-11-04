// API contract shared by the storefront and the mock server.
// Field names follow Django REST Framework conventions (snake_case, paginated lists).
// Text fields come back already translated: the client sends `?lang=ar|en`.

export type Lang = 'ar' | 'en'

export interface Paginated<T> {
  count: number
  next: number | null
  previous: number | null
  results: T[]
}

export interface CategoryRef {
  slug: string
  name: string
}

export interface CategoryNode extends CategoryRef {
  id: number
  emoji: string
  color: string
  image: string | null
  product_count: number
  children: CategoryNode[]
}

export interface Variant {
  sku: string
  label: string
  price: number
  sale_price: number | null
  in_stock: boolean
  stock: number
  /** Most a customer can order in one go (stock and per-order cap). */
  max_qty: number
}

export interface ProductSummary {
  id: number
  slug: string
  name: string
  brand: string
  image: string | null
  emoji: string
  color: string
  category: CategoryRef
  subcategory: CategoryRef | null
  unit_label: string
  /** Sold by the kilo: quantity is a weight in kg. */
  sold_by_weight: boolean
  qty_step: number
  min_qty: number
  max_qty: number
  price: number
  sale_price: number | null
  discount_percent: number
  sale_ends_at: string | null
  in_stock: boolean
  default_sku: string
  variants: Variant[]
  rating: number
  tags: string[]
}

export interface ProductDetail extends ProductSummary {
  description: string
  images: string[]
}

export interface HomeBanner {
  id: number
  title: string
  subtitle: string
  cta: string
  link: string
  emoji: string
  tone: 'green' | 'orange' | 'blue'
}

export interface HomeSection {
  key: string
  title: string
  link: string | null
  products: ProductSummary[]
}

export interface HomeData {
  banners: HomeBanner[]
  sections: HomeSection[]
}

export interface SearchSuggestion {
  type: 'product' | 'category'
  slug: string
  name: string
  emoji: string
  subtitle: string
}

export interface CartItemInput {
  sku: string
  qty: number
  /** Unit price the customer saw; lets the server flag price changes. */
  expected_price?: number
}

export type DeliveryMethod = 'delivery' | 'pickup'
export type PaymentMethod = 'cod' | 'card' | 'wallet'

export interface QuoteRequest {
  items: CartItemInput[]
  coupon?: string | null
  zone?: string | null
  method?: DeliveryMethod
}

export interface QuoteLine {
  sku: string
  qty: number
  available: boolean
  max_qty: number
  unit_price: number
  original_unit_price: number
  line_total: number
  price_changed: boolean
  variant_label: string
  product: ProductSummary
}

export interface QuoteWarning {
  code: 'unavailable' | 'price_changed' | 'min_order' | 'qty_reduced'
  message: string
}

export interface Quote {
  lines: QuoteLine[]
  items_count: number
  subtotal: number
  savings: number
  coupon_discount: number
  delivery_fee: number
  total: number
  min_order: number
  free_delivery_threshold: number
  remaining_for_free_delivery: number
  cod_available: boolean
  cod_limit: number
  coupon: { code: string; valid: boolean; message: string } | null
  warnings: QuoteWarning[]
  can_checkout: boolean
}

export interface Zone {
  id: string
  name: string
  fee: number
}

export interface DeliveryInfo {
  zones: Zone[]
  free_delivery_threshold: number
  min_order: number
  pickup: { name: string; address: string; hours: string }
}

export interface Slot {
  id: string
  start: string
  end: string
  available: boolean
  express: boolean
}

export interface SlotDay {
  date: string
  slots: Slot[]
}

export interface Address {
  id: number
  label: string
  zone: string
  zone_name: string
  area: string
  street: string
  building: string
  floor: string
  apartment: string
  notes: string
  lat: number | null
  lng: number | null
  is_default: boolean
}

export type AddressInput = Omit<Address, 'id' | 'zone_name' | 'is_default'> & { is_default?: boolean }

export interface User {
  id: number
  phone: string
  name: string
  email: string
  language: Lang
}

export interface AuthTokens {
  access: string
  refresh: string
  user: User
  is_new: boolean
}

export type OrderStatus =
  | 'pending_payment'
  | 'placed'
  | 'confirmed'
  | 'preparing'
  | 'out_for_delivery'
  | 'ready_for_pickup'
  | 'delivered'
  | 'cancelled'

export interface OrderItem {
  sku: string
  slug: string
  name: string
  variant_label: string
  emoji: string
  color: string
  image: string | null
  qty: number
  unit_price: number
  line_total: number
  sold_by_weight: boolean
}

export interface OrderTimelineStep {
  status: OrderStatus
  at: string | null
  done: boolean
}

export interface Order {
  id: number
  number: string
  status: OrderStatus
  created_at: string
  method: DeliveryMethod
  payment_method: PaymentMethod
  payment_status: 'pending' | 'paid' | 'failed' | 'cod'
  items: OrderItem[]
  subtotal: number
  coupon_discount: number
  delivery_fee: number
  total: number
  coupon: string | null
  notes: string
  address: Address | null
  slot: { date: string; start: string; end: string; express: boolean } | null
  timeline: OrderTimelineStep[]
}

export interface OrderCreateInput {
  items: CartItemInput[]
  coupon?: string | null
  method: DeliveryMethod
  address_id?: number | null
  slot_id?: string | null
  payment_method: PaymentMethod
  notes?: string
}

export interface OrderCreateResponse {
  order: Order
  /** Present for card/wallet: send the customer here to pay. */
  payment_url: string | null
}

// ---- Support chat ----

export interface ChatMessage {
  id: number
  conversation: number
  kind: 'text' | 'event'
  /** For kind "event": what happened. */
  event: '' | 'closed'
  sender: 'customer' | 'staff'
  sender_name: string
  body: string
  image: { url: string; width: number | null; height: number | null } | null
  order: { id: number; number: string } | null
  created_at: string
}

export interface ChatConversationRef {
  id: number
  status: 'open' | 'closed'
  /** Last message id the support team has seen (for ✓✓). */
  staff_last_read: number
  customer_last_read: number
}

/** GET /support/chat/ — the whole chat, new messages (`after`) or older ones (`before`). */
export interface ChatState {
  conversation: ChatConversationRef | null
  messages: ChatMessage[]
  has_older: boolean
  unread: number
}
