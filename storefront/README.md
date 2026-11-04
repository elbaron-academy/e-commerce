# Rocket Market — Storefront PWA

The customer storefront for **Rocket Market (روكت ماركت)**, the online supermarket of Rocket Mall.
It is a Progressive Web App: one codebase that works as a website (with SEO) and installs on phones like an app, including offline browsing.

Arabic is the default language (RTL), English is available under `/en`.

## Stack

| Area | Choice |
| --- | --- |
| Framework | Nuxt 4 (Vue 3, server-side rendering for SEO) |
| Styling | Tailwind CSS v4, RTL with logical utilities (`ms-`, `pe-`, `start-`…) |
| i18n | `@nuxtjs/i18n` — `ar` (default, RTL) and `en` (`/en/...`) |
| State | Pinia (`cart`, `auth`) |
| PWA | `@vite-pwa/nuxt` (Workbox): manifest, icons, service worker, install and update prompts |
| HTTP | `$fetch` (ofetch) client in `app/plugins/api.ts`. It replaces Axios because it works on the server and in the browser |
| Mock API | Nitro server routes under `/api/v1` that follow the Django REST conventions |

Nuxt 4 is the current major version of the Nuxt named in the sprint plan (Nuxt 3 is end of life).

## Getting started

From the repo root, `make web` runs the storefront against the local Django API and `make web-mock` runs it with the built-in mock (no backend needed). Or, inside `storefront/`:

```bash
npm install
npm run dev          # http://localhost:3000 with the mock API (service worker disabled in dev)
```

To try the PWA itself (install, offline, update prompt), run a production build:

```bash
npm run build
node .output/server/index.mjs   # http://localhost:3000
```

### Demo data

- **Login:** any Egyptian mobile number (`010…`, `011…`, `012…`, `015…`). The OTP code is always **`1234`**.
- **Coupons:** `ROCKET10` (10% off, min EGP 200, max EGP 100), `SAVE50` (EGP 50 off, min EGP 400), `FREESHIP` (free delivery, min EGP 150).
- **Store rules:** minimum order EGP 100, free delivery from EGP 500, cash on delivery up to EGP 3,000.
- **Order tracking:** mock orders move forward on their own (confirmed after 1 min, preparing at 3, out for delivery at 6, delivered at 10).
- **Payments:** card and wallet go to a test gateway page where you choose success or failure.
- 66 products in 8 categories, with sizes (variants), weight-based items (kg, 0.25 kg steps), sale prices and out-of-stock items. Brands are fictional and images are emoji placeholders until real photos arrive.

## What's in it

| Page | Path | Notes |
| --- | --- | --- |
| Home | `/` | Banners, categories, deals, best sellers, fresh produce |
| Categories | `/categories` | All categories with subcategories |
| Category | `/category/:slug` | Subcategory chips, sort, "load more" (24 per page); filters live in the URL |
| Product | `/product/:slug` | Sizes, sale end date, low stock, weight note, related items, schema.org JSON-LD |
| Search | `/search?q=` · `/search?tag=offer` | Suggestions after 2 letters, recent searches, Arabic normalization and typo tolerance |
| Cart | `/cart` | Saved on the device, priced by the server, coupon, free-delivery progress, warnings |
| Checkout | `/checkout` | Delivery or pickup, addresses with GPS, delivery slots + express, cash/card/wallet |
| Login | `/login` | Phone + OTP, accepts Arabic digits, WebOTP autofill on Android |
| Account | `/account` | Profile, addresses, language, install app, sign out |
| Orders | `/orders`, `/orders/:id` | History, live tracking timeline, "Order again", "Question about this order? Chat with us" |
| Chat | `/chat`, `/chat?order=:id` | Chat with the support team: photos, read ticks (✓ sent, ✓✓ seen), unread badge in the header |

Pages that depend on the user or the cart (`/cart`, `/checkout`, `/login`, `/account`, `/orders`, `/payment`, `/chat`) render in the browser only. Catalog pages are server-rendered for SEO.

## PWA behaviour

| What | How |
| --- | --- |
| Install | Manifest (RTL, Arabic), maskable icons, shortcuts to Cart and Orders. Install banner on Android/desktop, "Add to Home Screen" steps on iOS Safari |
| Updates | `registerType: 'prompt'`: a "new version" toast asks before reloading, so a checkout is never interrupted |
| App shell | JS, CSS, icons and `offline.html` are precached |
| Pages | Network first (4 s timeout), cached copy when offline, `offline.html` for pages never visited |
| Catalog API | `home`, `categories`, `products`, `search`: stale-while-revalidate (instant, refreshed in the background) |
| Cart, checkout, auth, orders | Network only. The cart itself is kept in `localStorage`, so it survives offline and syncs across tabs |
| Images, fonts, translations | Cache first |

Change the logo in `public/logo.svg`, then run `npm run generate-pwa-assets` to regenerate the icons.

## Connecting the Django backend

The real API lives in [`../backend`](../backend/README.md) and implements the same contract as the mock ([`docs/api-contract.md`](docs/api-contract.md)). Point the storefront at it with environment variables (see `.env.example`):

```bash
NUXT_PUBLIC_API_BASE=https://api.rocket.hossam-ameen.online/api/v1   # used by browsers
NUXT_API_BASE_SERVER=http://127.0.0.1:8000/api/v1                    # optional, used during server rendering
NUXT_PUBLIC_SITE_URL=https://rocket.hossam-ameen.online
NUXT_MOCK_API=false
```

The TypeScript types in `shared/types/api.ts` describe every payload.

## Project structure

```
app/
  components/   UI (ProductCard, AddToCart, QtyStepper, SearchBox, PWA banners…)
  composables/  useApiFetch, useFormat (money/qty/dates), useToast, useOnline…
  pages/        routes (see table above)
  plugins/      api.ts ($api client), cart.client.ts (load/save cart)
  stores/       cart.ts, auth.ts
i18n/locales/   ar.json, en.json
server/         mock API (api/v1/*) and its data (utils/catalog-data.ts)
shared/         types and helpers used by both app and server
public/         icons, offline.html, robots.txt
docs/           API contract and sprint mapping
```

## Status against the sprint plan

See [`docs/sprint-mapping.md`](docs/sprint-mapping.md) for what is done per task and what is left.
