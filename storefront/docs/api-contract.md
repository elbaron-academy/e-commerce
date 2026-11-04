# API contract (storefront ↔ backend)

This is what the storefront expects from the API. Both the mock server in `server/api/v1` and the Django backend in `../backend` implement it, and `shared/types/api.ts` defines every payload. The live, complete reference (including the staff API) is the backend's Swagger page at `/api/docs/`.

## Conventions

- Base path `/api/v1`. Paths end with a slash (`/products/banana/`), as Django expects.
- JSON with `snake_case` fields. Money is a number in EGP (`38`, `7.5`), and prices include VAT.
- **Language:** every request carries `?lang=ar|en` and `Accept-Language`. Responses return text already translated (`name`, `label`, `message`…). The query parameter is there so the service worker and CDN cache each language separately, which means Django needs a small middleware that activates `lang` from the query.
- **Auth:** `Authorization: Bearer <access JWT>`. Access tokens last 1 day by default (`JWT_ACCESS_MINUTES`). `POST /auth/token/refresh/ {refresh}` returns a new pair. The storefront doesn't refresh yet; on `401` it signs the user out.
- **Lists** are paginated: `{ count, next, previous, results }` where `next`/`previous` are page numbers (or `null`). Default `page_size` is 24.
- **Errors:** `{ "detail": "Human readable message", "code": "machine_code" }`, plus `field` for validation errors (and `quote` on a `409` from checkout). Messages are translated and can be shown to the customer as-is.

## Catalog (public, cacheable)

| Method | Path | Query | Returns |
| --- | --- | --- | --- |
| GET | `/home/` | | `HomeData` (banners + product sections) |
| GET | `/categories/` | | `CategoryNode[]` (tree with children) |
| GET | `/categories/{slug}/products/` | `sub`, `sort`, `page`, `page_size` | `Paginated<ProductSummary>` |
| GET | `/products/` | `category`, `tag` (`offer`/`best`/`new`), `exclude`, `sort`, `page`, `page_size` | `Paginated<ProductSummary>` |
| GET | `/products/{slug}/` | | `ProductDetail` |
| GET | `/search/` | `q` or `tag`, `sort`, `page` | `Paginated<ProductSummary>` |
| GET | `/search/autocomplete/` | `q` (min 2 chars) | `SearchSuggestion[]` (max ~8) |

`sort` is one of `recommended`, `best`, `price_asc`, `price_desc`, `discount`, `newest`.

Product notes:
- Each product has one or more `variants` (sizes), each with a unique `sku`, `price`, `sale_price`, `stock`, `max_qty`.
- `sold_by_weight: true` means the quantity is in kg, using `qty_step` (0.25) and `min_qty` (0.5).
- The `default_sku` is the first variant in stock. Product-level `price`, `sale_price` and `unit_label` mirror it.

## Cart & checkout

The cart lives on the device (offline-friendly). The server prices it on every change:

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| POST | `/cart/quote/` | `{ items: [{ sku, qty, expected_price? }], coupon?, zone?, method? }` | `Quote` |
| GET | `/delivery/info/` | | zones with fees, free-delivery threshold, minimum order, pickup point |
| GET | `/delivery/slots/` | | `SlotDay[]` (today and the next 2 days, with an `express` slot today) |
| POST | `/orders/` 🔒 | `OrderCreateInput` | `201 { order, payment_url }` |

`Quote` returns per-line availability, `price_changed` (compared with `expected_price`), capped quantities, coupon result, delivery fee, `can_checkout` and translated `warnings`. `POST /orders/` re-runs the same checks and answers `409` with `{ detail, quote }` if something changed.

For card or wallet, `payment_url` is where the browser goes next (the real gateway page, absolute URL). For cash on delivery it is `null`.

When the server-side cart from BE-401/402 is ready, the same `Quote` shape can come back from it. The app only needs the endpoint swapped.

## Account 🔒

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| POST | `/auth/otp/send/` | `{ phone }` (Egyptian `01xxxxxxxxx`) | `{ sent, expires_in, resend_in }`, `429` when rate-limited |
| POST | `/auth/otp/verify/` | `{ phone, code }` | `AuthTokens` (`access`, `refresh`, `user`, `is_new`) |
| POST | `/auth/token/refresh/` | `{ refresh }` | `{ access, refresh }` |
| GET / PATCH | `/me/` | `{ name?, email?, language? }` | `User` |
| POST | `/me/phone/` | `{ phone, code }` (OTP sent to the new number first) | `User` |
| GET / POST | `/addresses/` | `AddressInput` | `Address[]` / `201 Address` |
| PATCH | `/addresses/{id}/` | any address fields, `is_default` | `Address` |
| DELETE | `/addresses/{id}/` | | `204` |
| GET | `/orders/` | | `Paginated<Order>` |
| GET | `/orders/{id}/` | | `Order` with `timeline` |

## Support chat 🔒

The customer sees one continuous chat. The server groups it into conversations: staff close one when the issue is solved, and the customer's next message opens a new one. While the chat is open, the client polls `GET /support/chat/?after=<last id>` every 3 seconds (every 15 in a background tab), which returns only new messages.

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| GET | `/support/chat/` | `?after=<id>` new messages, `?before=<id>` older ones, nothing for the latest 30 | `ChatState` (`conversation`, `messages` oldest first, `has_older`, `unread`) |
| POST | `/support/chat/messages/` | JSON `{ body, order? }`, or multipart with `image` (JPG/PNG/WebP, ≤ 8 MB) | `201 ChatMessage` |
| POST | `/support/chat/read/` | `{ message_id? }` (default: everything) | `{ unread }` |
| GET | `/support/chat/unread/` | | `{ unread }`, for the badge (polled every minute) |

A message has `sender` (`customer` or `staff`), `body`, `image` (`{ url, width, height }`), `order` (`{ id, number }`) and `kind`: `text`, or `event` with `event: "closed"` when staff ended the conversation. `conversation.staff_last_read` is the last message id staff have seen, for the ✓✓. Photos are resized to 1600 px and saved again without their EXIF data (no location). Sending is limited to 30 messages a minute (`CHAT_MESSAGE_RATE`).

For WebOTP autofill on Android, the SMS must end with a line like `@rocket-market.example #1234` (the site's domain).

Payments: `POST /payments/webhook/{provider}/` receives signed gateway callbacks (each event handled once). With the test gateway (`PAYMENT_PROVIDER=dummy`), the storefront's `/payment/mock` page calls `POST /payments/mock/confirm/ { order_id, result }`. That endpoint returns 404 once a real gateway is configured.
