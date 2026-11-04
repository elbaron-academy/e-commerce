# Deploying Rocket Market

| | URL | On the VM |
| --- | --- | --- |
| Storefront | https://rocket.hossam-ameen.online | `/var/www/html/rocket` (Nuxt server on 127.0.0.1:3000) |
| API | https://api.rocket.hossam-ameen.online | `/opt/rocket` (gunicorn on 127.0.0.1:8000) |

VM: `hossam@35.226.179.10`. nginx sits in front of both, with HTTPS from Let's Encrypt. Services run with systemd (no Docker on the server for now). The database is SQLite in `/opt/rocket/data/db.sqlite3`, backed up every night.

Every push to `main` runs the tests and, if they pass, deploys both apps through GitHub Actions.

## One-time setup

### 1. DNS and firewall

- Create two **A records** pointing to `35.226.179.10`: `rocket.hossam-ameen.online` and `api.rocket.hossam-ameen.online`.
- In Google Cloud, allow **HTTP and HTTPS** traffic to the VM (VM → Edit → Firewalls, or a firewall rule for ports 80/443).

### 2. Create the deploy key and add it to GitHub

Run this on your computer. It creates a key on the VM that only GitHub Actions uses, authorizes it, and prints the private key:

```bash
ssh hossam@35.226.179.10 'test -f ~/.ssh/rocket_deploy || ssh-keygen -q -t ed25519 -N "" -C github-actions-rocket -f ~/.ssh/rocket_deploy; touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; grep -qxF "$(cat ~/.ssh/rocket_deploy.pub)" ~/.ssh/authorized_keys || cat ~/.ssh/rocket_deploy.pub >> ~/.ssh/authorized_keys; cat ~/.ssh/rocket_deploy'
```

(`make deploy-key` runs the same command.)

Copy everything it prints, from `-----BEGIN OPENSSH PRIVATE KEY-----` to `-----END OPENSSH PRIVATE KEY-----`. In GitHub, go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret | Value |
| --- | --- |
| `DEPLOY_SSH_KEY` | the private key you just copied |
| `DEPLOY_KNOWN_HOSTS` | optional but recommended: the output of `ssh-keyscan -H 35.226.179.10` (or `make known-hosts`) |

The host (`35.226.179.10`) and user (`hossam`) are already defaults in the workflow. To change them, add repository **variables** `DEPLOY_HOST` and `DEPLOY_USER`.

> If Google Cloud manages your SSH keys (OS Login), a key added to `authorized_keys` may be ignored. In that case add the public key (`~/.ssh/rocket_deploy.pub` on the VM) under Compute Engine → Metadata → SSH keys for user `hossam`.

### 3. Prepare the server

Pick one of these:

- **From GitHub:** Actions → **Server setup** → Run workflow (optionally enter an email for certificate expiry notices). It needs `hossam` to have passwordless sudo, which is the default on Google Cloud.
- **From your computer:** `make server-setup`, or by hand:

  ```bash
  scp -r deploy hossam@35.226.179.10:/tmp/rocket-setup
  ```

  ```bash
  ssh -t hossam@35.226.179.10 'sudo CERTBOT_EMAIL=you@example.com bash /tmp/rocket-setup/scripts/server-setup.sh'
  ```

The setup script is safe to run again. It:

- installs nginx, Python 3, Node.js 22 and certbot
- creates `/opt/rocket` and `/var/www/html/rocket` (owned by `hossam`)
- writes `/opt/rocket/.env` with a freshly generated Django `SECRET_KEY` and webhook secret (only if the file doesn't exist yet)
- installs the systemd services (`rocket-api`, `rocket-web`) and timers (`rocket-jobs` every minute, `rocket-backup` nightly)
- lets `hossam` restart those services without a password (used by CI/CD)
- gets HTTPS certificates. If DNS isn't ready yet, the sites run over HTTP. Run the script again once DNS works.

It doesn't touch other nginx sites on the machine.

### 4. Deploy

Push to `main`, or run **Actions → CI/CD → Run workflow**. On the first deploy the database is created and the demo catalog is loaded.

Create your admin account on the VM:

```bash
ssh -t hossam@35.226.179.10 'cd /opt/rocket/backend && DJANGO_SETTINGS_MODULE=config.settings.prod DJANGO_ENV_FILE=/opt/rocket/.env /opt/rocket/venv/bin/python manage.py createsuperuser'
```

Then sign in at https://api.rocket.hossam-ameen.online/admin/ (phone + password). API docs: https://api.rocket.hossam-ameen.online/api/docs/

## How a deploy works

1. CI runs backend lint and tests, and builds and type-checks the storefront.
2. It uploads two archives to `/opt/rocket/incoming/`.
3. `deploy-backend.sh` unpacks to `/opt/rocket/releases/backend-<sha>`, installs packages into `/opt/rocket/venv`, runs migrations, `collectstatic` and the role setup, points `/opt/rocket/backend` at the new release and restarts `rocket-api`.
4. `deploy-storefront.sh` unpacks to `/var/www/html/rocket/releases/<sha>`, points `/var/www/html/rocket/current` at it and restarts `rocket-web`.
5. Health checks run after each step. The last 5 releases are kept.

## Day to day

| Task | Command |
| --- | --- |
| Service status | `make status` |
| API logs | `make logs-api` |
| Storefront logs | `make logs-web` |
| Roll back the API / storefront | `make rollback-api` / `make rollback-web` |
| Edit production settings | `ssh hossam@35.226.179.10 'nano /opt/rocket/.env'`, then `sudo systemctl restart rocket-api` |
| Backups | `/opt/rocket/backups/db-*.sqlite3.gz` (14 days) |

## Files on the VM

```
/opt/rocket/
  .env                  API settings and secrets (never in git)
  storefront.env        storefront settings
  backend -> releases/backend-<sha>/backend
  deploy  -> releases/backend-<sha>/deploy
  venv/                 Python packages
  data/db.sqlite3       database
  media/  static/       uploads and admin static files (served by nginx)
  backups/
/var/www/html/rocket/
  current -> releases/<sha>
```

## Before going live for real

- Connect an SMS provider and **remove `OTP_FIXED_CODE=1234`** from `/opt/rocket/.env`. Until then, every login code is 1234.
- Choose the payment gateway (BE-504) and set `PAYMENT_PROVIDER`. `dummy` sends customers to a test payment page.
- Set `STAFF_ALERT_EMAILS` and the `EMAIL_*` settings for low-stock emails, and `SENTRY_DSN` for error tracking.
- When traffic grows: move to PostgreSQL (`DATABASE_URL`) and add Redis (`REDIS_URL`, `CELERY_BROKER_URL`). No code changes needed.
