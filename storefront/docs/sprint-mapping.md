# Storefront tasks vs. the sprint plan

Status of the `FE-` tasks from the sprint plan in this codebase, plus the PWA tasks to add.

✅ done · 🟡 partly done · ⬜ not started

## Existing FE tasks

| ID | Task | Status | Notes |
| --- | --- | --- | --- |
| FE-001 | Nuxt project: i18n, RTL, Tailwind, API client | ✅ | Nuxt 4; `$fetch` client instead of Axios |
| FE-101 | Header, footer, language switch | ✅ | |
| FE-102 | OTP sign-up/login, password reset | 🟡 | OTP done (Arabic digits, WebOTP). Email password reset (US-32) not built |
| FE-103 | Profile page | ✅ | |
| FE-201 | Category menu and home page | 🟡 | Desktop category bar, not a full mega menu yet |
| FE-202 | Category page, product card, pagination (SSR) | ✅ | "Load more" with 24 per page |
| FE-301 | Product page: gallery with zoom, variants, SEO | 🟡 | Variants, prices, SEO and JSON-LD done. Image gallery and zoom wait for real photos |
| FE-302 | Search bar with suggestions, results page | ✅ | |
| FE-303 | Filters and sort saved in the URL | 🟡 | Subcategory and sort done. Brand/price facets need BE-305 |
| FE-401 | Mini cart, cart page, coupon | 🟡 | Cart page and coupon done. No slide-out mini cart |
| FE-402 | Address book with Google Maps | 🟡 | Address book with GPS position. Map picker not built |
| FE-501 | Checkout pages | ✅ | One page: method, address, slot, payment, notes |
| FE-502 | Payment redirect, success and failure | 🟡 | Flow works against a mock gateway. Needs the real gateway (BE-504) |
| FE-601 | Order history, details, tracking, invoice | 🟡 | Invoice download waits for BE-603 |
| FE-701 | Performance, sitemap, robots, analytics | 🟡 | robots.txt only |
| FE-702 | Static pages (about, returns, privacy) | ⬜ | |

## PWA tasks to add to the plan

| Suggested ID | Task | Sprint | Status |
| --- | --- | --- | --- |
| FE-002 | PWA setup: manifest, icons, service worker, caching strategy, offline page | 0 | ✅ |
| FE-104 | Install banner (Android/desktop) and iOS "Add to Home Screen" guide; update prompt | 1 | ✅ |
| FE-403 | Offline cart: saved on device, synced across tabs, re-priced when back online | 4 | ✅ |
| FE-503 | Web Push for order updates (FCM web or VAPID), permission prompt after first order | 5 | ⬜ needs BE-506 to add a web-push channel |
| FE-602 | Live order tracking: polling now, push-triggered refresh later | 6 | 🟡 polling every 20 s |
| FE-703 | PWA audit: Lighthouse PWA/performance, testing on low-end Android and iOS Safari | 7 | ⬜ |

## Decision needed

The plan has a Flutter app for Android and iOS. With a PWA you can:

- **Keep both:** the PWA covers web and mobile browsers, and Flutter ships to the stores.
- **Go PWA-first:** launch with the PWA only and decide on store apps after launch. This frees the two Flutter developers for the backend and admin work. Limits to know: on iOS, push notifications only work after the customer installs the PWA (iOS 16.4+), and the PWA does not appear in the App Store unless it's wrapped (for example with Capacitor or a Trusted Web Activity on Android).
