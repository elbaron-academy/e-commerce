# Rocket Market — API (Django REST Framework)

Backend for the storefront, the mobile app and the admin dashboard.

- Django 5.2 LTS, Django REST Framework, JWT (simplejwt), drf-spectacular (OpenAPI)
- SQLite for now (configured in `.env`); PostgreSQL by changing `DATABASE_URL`
- Celery for background jobs when a broker is configured, otherwise jobs run inline
- Arabic (default) and English: every request can pass `?lang=ar|en`

## Run it

From the repo root:

```bash
make backend-install   # .venv + packages + backend/.env
make migrate seed      # database + demo catalog (66 products)
make api               # http://localhost:8000/api/docs/
```

`make dev` runs the API and the storefront together. `make test` runs the tests (87 tests, 95% coverage).

Demo login: any Egyptian mobile number, code `1234`. Coupons: `ROCKET10`, `SAVE50`, `FREESHIP`.
Admin: `python manage.py ensure_admin --email you@example.com --password '…'` (or `make superuser`), then sign in at http://localhost:8000/admin/ with the email or phone.

## Apps

| App | What it does | Sprint plan |
| --- | --- | --- |
| `core` | Language from `?lang=`, `{detail, code}` errors, pagination, staff permissions, Arabic text normalization, catalog cache | BE-002 |
| `accounts` | Phone users, OTP login (hashed codes, 5 per hour, 60 s resend, 5 attempts), JWT, profile, phone change, addresses, staff roles | BE-101 → BE-105, BE-405, BE-607 |
| `catalog` | Categories (3 levels), brands, vendors, products, sized variants with SKU, sale windows, stock, weight items, photos, banners, home rows, search | BE-201 → BE-208, BE-301 → BE-306 |
| `shipping` | Delivery zones and fees, delivery windows with capacity, store rules (free delivery, minimum order, COD limit, pickup) | BE-406 |
| `promotions` | Coupons: percent / fixed / free delivery, minimum, cap, dates, total and per-customer limits | BE-404 |
| `orders` | Cart pricing, checkout in one transaction, stock reservation, status machine with history, timeline, dashboard | BE-401/403, BE-501 → BE-503, BE-601 → BE-606 |
| `payments` | Gateway interface, test gateway, signed webhooks handled once, late payments flagged for refund | BE-504 |
| `notifications` | SMS / email / push with Arabic and English templates and a send log | BE-506 |

## Design notes

- **Cart:** the cart lives on the customer's device (works offline) and `POST /cart/quote/` prices it on every change. Checkout runs the same pricing inside a transaction with row locks, so the order always matches what was shown. This replaces the Redis cart planned in BE-401/402. Guest carts need no merge step.
- **Stock:** reserved when the order is created. Unpaid card/wallet orders release their stock after 15 minutes (`release_expired_reservations`, run every minute). Cancelling restocks.
- **SQLite:** transactions take the write lock at the start (`IMMEDIATE`) and WAL mode is on, so two checkouts can't sell the last item twice.
- **Search:** runs on the main database with Arabic normalization (أ/ا, ة/ه, ى/ي), the definite article and typo tolerance. Fine for a few thousand products. Meilisearch (BE-302) can replace it behind the same function.
- **Status changes:** only allowed moves (`Order.TRANSITIONS`). Each change is recorded, and the customer gets an SMS for the key steps.
- **Translations:** models have `_ar` and `_en` columns. Responses return the active language.

## API

Interactive docs at `/api/docs/` (Swagger) and `/api/redoc/`. The storefront contract is in [`../storefront/docs/api-contract.md`](../storefront/docs/api-contract.md).

Staff API under `/api/v1/admin/` (phone + password login at `admin/auth/login/`). Each endpoint checks Django model permissions, and roles are Django groups (`make roles` creates Admin, Catalog manager, Order manager and Support):

`dashboard/`, `orders/` (+ `{id}/transition/`), `products/` (+ `{id}/images/`), `variants/` (stock, `?low_stock=true`), `categories/`, `brands/`, `vendors/`, `banners/`, `home-sections/`, `coupons/` (+ `{id}/redemptions/`), `zones/`, `delivery-windows/`, `settings/`, `customers/`, `staff/`, `roles/`, `permissions/`, `notifications/`.

## Not built yet

- Real SMS provider and payment gateway (Paymob or another). Both plug into existing interfaces (`SMS_BACKEND`, `apps/payments/gateways/`).
- FCM push to devices (needs device tokens from the mobile app, MOB-504).
- PDF invoices and shipping labels (BE-603), refunds through the gateway (BE-604).
- Image thumbnails (BE-204) and Meilisearch (BE-302).
- R2 features: reviews, wishlist, returns, Excel import, reports.
