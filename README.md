# Rocket Market

Online supermarket for Rocket Mall: an installable storefront (PWA) and its API.

| Folder | What | Stack |
| --- | --- | --- |
| [`storefront/`](storefront/README.md) | Customer storefront, Arabic (RTL) + English, works offline | Nuxt 4 (Vue 3), Tailwind, Pinia, Workbox |
| [`mobile/`](mobile/README.md) | Android and iOS app with the same screens as the storefront | Flutter, BLoC/Cubit, GetIt, Dio, go_router |
| [`backend/`](backend/README.md) | API for the storefront, mobile app and admin dashboard | Django 5.2 + DRF, SQLite (PostgreSQL-ready), Celery |
| [`deploy/`](deploy/README.md) | Server setup and deploy scripts, nginx, systemd | Ubuntu/Debian VM |
| `.github/workflows/` | CI/CD: tests on every push (plus an Android APK), deploy on `main` | GitHub Actions |

Live: https://rocket.hossam-ameen.online · API: https://api.rocket.hossam-ameen.online/api/docs/

## Quick start

You need Python 3.10+ and Node.js 22 (and Flutter 3.47 for the mobile app).

```bash
make setup   # install everything, create the SQLite database, load demo data
```

```bash
make dev     # API on :8000 and storefront on :3000
```

Open http://localhost:3000. Sign in with any Egyptian mobile number and the code `1234`. Coupons: `ROCKET10`, `SAVE50`, `FREESHIP`.

Mobile app: with the API running, `make mobile-install mobile` starts it on an emulator or a connected phone (see [`mobile/README.md`](mobile/README.md)).

Run `make` to see every command (tests, lint, Docker, server tasks).

## Docker

```bash
make docker-up
```

This starts the API, background worker and scheduler, Redis and the storefront. It's for local use only; the server runs systemd services (see [`deploy/`](deploy/README.md)).

## Deployment

Pushing to `main` deploys automatically once the one-time setup in [`deploy/README.md`](deploy/README.md) is done (DNS, deploy key secret, server setup).
