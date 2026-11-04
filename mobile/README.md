# Rocket Market — Mobile app (Flutter)

The Android and iOS app for Rocket Market. It has the same screens and flows as the [storefront](../storefront/README.md) and talks to the same [API](../backend/README.md).

Arabic is the default language (right to left). English can be chosen on the account screen.

## Stack

| Area | Choice |
| --- | --- |
| Framework | Flutter 3.47 (Dart 3.13), Material 3, Cairo font |
| Architecture | Clean Architecture per feature: `domain` (entities, repository interfaces), `data` (API mappers, repositories), `presentation` (pages, Cubits) |
| State | `flutter_bloc` Cubits |
| Dependency injection | `get_it` (`lib/app/di.dart`) |
| HTTP | Dio with interceptors for language (`?lang=` and `Accept-Language`), JWT with refresh, and an offline cache for the catalog |
| Navigation | `go_router` with a bottom-bar shell (home, categories, cart, orders, account) |
| Translations | `gen-l10n` from `lib/l10n/arb/app_ar.arb` and `app_en.arb` (the same texts as the storefront) |
| Storage | Tokens in `flutter_secure_storage`. Cart, recent searches and cached catalog responses in `shared_preferences` |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, and JSON fixtures recorded from the real API |

## Run it

From the repo root, start the API first (`make api`). Then:

```bash
make mobile-install   # flutter pub get
make mobile           # dev flavor against the local API
```

Or inside `mobile/`:

```bash
flutter run -t lib/main_dev.dart        # local API (http://10.0.2.2:8000 from the Android emulator)
flutter run -t lib/main_staging.dart
flutter run -t lib/main_prod.dart       # https://api.rocket.hossam-ameen.online
```

On an iOS simulator or a real phone, point the dev flavor at your computer:

```bash
flutter run -t lib/main_dev.dart --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Demo login: any Egyptian mobile number, code `1234`. Coupons: `ROCKET10`, `SAVE50`, `FREESHIP`.

### Flavors

| Flavor | Entry point | API |
| --- | --- | --- |
| dev | `lib/main_dev.dart` | `http://10.0.2.2:8000/api/v1` (your computer, from the Android emulator) |
| staging | `lib/main_staging.dart` | production API for now (no staging server yet) |
| prod | `lib/main_prod.dart` (also `lib/main.dart`) | `https://api.rocket.hossam-ameen.online/api/v1` |

`--dart-define=API_BASE_URL=...` overrides the address for any flavor. The flavor is shown at the bottom of the account screen.

## Tests and checks

```bash
make mobile-test      # flutter test
make mobile-lint      # dart format check + flutter analyze
make mobile-apk       # release APK (prod flavor) → mobile/build/app/outputs/flutter-apk/
```

CI runs the format check, `flutter analyze` and the tests on every push, then builds a release APK. Download it from the workflow run page under **Artifacts → rocket-market-apk**.

## Project layout

```
lib/
  app/          config (flavors), bootstrap, dependency injection, router, theme, bottom-bar shell
  core/         API client and interceptors, secure storage, formatters, shared widgets
  features/
    catalog/    home, categories, category products, product, search
    cart/       cart, live pricing, coupon, free-delivery bar
    auth/       OTP login, session
    account/    profile, addresses (with current location), language
    checkout/   delivery or pickup, address, delivery window, payment, place order
    orders/     my orders, order details, status timeline, reorder
    settings/   language
  l10n/         arb/ (source texts) and gen/ (generated, run `flutter gen-l10n` after editing)
```

## How it works

- **Cart:** stored on the phone like the storefront, so it works offline and guests need no merge after login. Every change is re-priced by `POST /cart/quote/`. Checkout sends the same items, so the total matches what the customer saw.
- **Login:** phone, then the 4-digit code (keyboard autofill, verifies as soon as the 4th digit is entered), then the name for new customers. Staff accounts can't sign in with a code.
- **Tokens:** the access token is renewed with the refresh token when a request gets a 401. Requests that arrive while it's renewing wait and then retry. If renewal fails, the customer is signed out with a message.
- **Offline:** home, categories, products, search and delivery info are cached after the first load and shown with an "offline" banner when there's no connection.
- **Payment:** cash on delivery goes straight to the order. Card and wallet open the gateway page. Until a gateway is chosen (BE-504), that is the API's test payment page.
- **Order status:** the details screen refreshes every 20 seconds while it's open, and the lists support pull to refresh.

## Sprint plan coverage

| Task | Status |
| --- | --- |
| MOB-001 Clean Architecture, flavors, GetIt, Dio, BLoC, l10n | Done. Flavors are Dart entry points, not Android/iOS build flavors yet |
| MOB-002 Design system | Done (`app/theme.dart`, `core/widgets/`) |
| MOB-101 Splash, onboarding, language | Native splash and language switch. No onboarding screens |
| MOB-102 OTP login with autofill | Done with keyboard autofill. Android SMS User Consent API not added |
| MOB-103 Secure tokens, refresh interceptor | Done |
| MOB-104 Profile | Done |
| MOB-105 Crashlytics, Analytics, Fastlane | Not yet. Error hooks are ready in `app/bootstrap.dart` |
| MOB-201 → 203 Home, categories, infinite scroll, image cache, loading placeholders | Done |
| MOB-301 → 303 Product (gallery, sizes, sold-out disabled), search with suggestions and history, sort sheet | Done |
| MOB-304 Deep links | Routes match the storefront URLs (`/product/<slug>`, `/category/<slug>`). App Links and Universal Links config not added |
| MOB-401, 402, 404 Cart, guest cart, badge | Done |
| MOB-403 Addresses with GPS | Current location done. No map picker yet |
| MOB-501, 503 Checkout and confirmation | Done (one page with sections, like the storefront) |
| MOB-502 Payment in WebView or gateway SDK | Opens the gateway page. Waiting for the gateway choice |
| MOB-504 FCM push | Not yet (needs a Firebase project) |
| MOB-601, 603 Orders, timeline, pull to refresh | Done. Status refreshes by polling until push exists |
| MOB-602 PDF invoice | Not yet (the API doesn't make invoices yet, BE-603) |
| MOB-701, 702 Store listing and release | Not yet |

## Releasing

- **Android:** create an upload key and put its details in `android/key.properties` (see the comment at the top of `android/app/build.gradle.kts`). Without it, release builds are signed with the debug key, which is fine for testing but not for Google Play. Change the version in `pubspec.yaml` (`version: 1.0.0+1`).
- **iOS:** needs a Mac with Xcode. Run `flutter build ipa -t lib/main_prod.dart` and set the team and bundle ID (`com.rocketmall.rocketMarket`) in Xcode.
