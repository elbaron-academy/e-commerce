# Rocket Market — common commands. Run `make` to see them all.

SHELL := /bin/bash
VENV := backend/.venv
PY := $(CURDIR)/$(VENV)/bin/python
MANAGE := cd backend && $(PY) manage.py
# Tools inside the backend virtualenv, relative to backend/
BIN := .venv/bin
SSH_TARGET ?= hossam@35.226.179.10
API_PORT ?= 8000
WEB_PORT ?= 3000

.DEFAULT_GOAL := help
.PHONY: help install backend-install storefront-install setup dev api web web-mock worker beat \
        migrate makemigrations seed superuser roles shell reset-db \
        test test-backend test-storefront coverage lint format check build \
        docker-build docker-up docker-down docker-logs docker-seed \
        mobile-install mobile mobile-prod mobile-test mobile-lint mobile-format mobile-l10n mobile-apk \
        deploy-key known-hosts server-setup ssh logs-api logs-web status rollback-api rollback-web

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n"} \
		/^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} \
		/^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

##@ Setup
install: backend-install storefront-install ## Install backend and storefront dependencies

backend-install: ## Create backend/.venv, install packages, create backend/.env
	test -d $(VENV) || python3 -m venv $(VENV)
	$(VENV)/bin/pip install -q --upgrade pip
	$(VENV)/bin/pip install -q -r backend/requirements-dev.txt
	test -f backend/.env || cp backend/.env.example backend/.env

storefront-install: ## Install storefront packages
	cd storefront && npm ci

setup: install migrate seed ## First run: install, create the database, load demo data

##@ Run locally
dev: ## API on :8000 + storefront on :3000 using the real API (Ctrl+C stops both)
	@trap 'kill 0' EXIT; $(MAKE) --no-print-directory api & $(MAKE) --no-print-directory web & wait

api: ## Django API on :8000 (docs at /api/docs/)
	$(MANAGE) runserver 0.0.0.0:$(API_PORT)

web: ## Storefront on :3000 against the local API
	cd storefront && NUXT_PUBLIC_API_BASE=http://localhost:$(API_PORT)/api/v1 NUXT_MOCK_API=false npx nuxt dev --port $(WEB_PORT)

web-mock: ## Storefront on :3000 with its built-in mock API (no backend needed)
	cd storefront && npx nuxt dev --port $(WEB_PORT)

worker: ## Celery worker (needs CELERY_BROKER_URL in backend/.env)
	cd backend && $(BIN)/celery -A config worker --loglevel=info

beat: ## Celery beat scheduler (needs CELERY_BROKER_URL)
	cd backend && $(BIN)/celery -A config beat --loglevel=info

##@ Database
migrate: ## Apply migrations
	$(MANAGE) migrate

makemigrations: ## Create migrations after model changes
	$(MANAGE) makemigrations

seed: ## Load the demo catalog (safe to run again)
	$(MANAGE) seed_demo

superuser: ## Create an admin user (phone + password)
	$(MANAGE) createsuperuser

roles: ## Create the default staff roles
	$(MANAGE) setup_roles

shell: ## Django shell
	$(MANAGE) shell

reset-db: ## Delete the local SQLite database and start fresh with demo data
	rm -f backend/db.sqlite3 backend/db.sqlite3-wal backend/db.sqlite3-shm
	rm -rf backend/.cache
	$(MAKE) --no-print-directory migrate seed

##@ Quality
test: test-backend test-storefront ## All tests

test-backend: ## Backend tests
	cd backend && $(PY) -m pytest

test-storefront: ## Storefront type check
	cd storefront && npx nuxt typecheck

coverage: ## Backend tests with coverage report
	cd backend && $(PY) -m pytest --cov --cov-report=term-missing

lint: ## Lint backend code
	cd backend && $(BIN)/ruff check . && $(BIN)/ruff format --check .

format: ## Format backend code
	cd backend && $(BIN)/ruff format . && $(BIN)/ruff check --fix .

check: lint test ## Lint + tests (same as CI)

build: ## Production build of the storefront
	cd storefront && npm run build

##@ Mobile app (Flutter, in mobile/)
DART_SOURCES = $$(find lib test -name '*.dart' -not -path 'lib/l10n/gen/*')

mobile-install: ## Install the app's packages
	cd mobile && flutter pub get

mobile: ## Run the app (dev flavor) against the local API; needs `make api`
	cd mobile && flutter run -t lib/main_dev.dart

mobile-prod: ## Run the app against the production API
	cd mobile && flutter run -t lib/main_prod.dart

mobile-test: ## App tests
	cd mobile && flutter test

mobile-lint: ## Format check + static analysis
	cd mobile && dart format --output=none --set-exit-if-changed $(DART_SOURCES) && flutter analyze

mobile-format: ## Format the app's code
	cd mobile && dart format $(DART_SOURCES)

mobile-l10n: ## Regenerate translations after editing lib/l10n/arb/*.arb
	cd mobile && flutter gen-l10n

mobile-apk: ## Release APK (prod flavor)
	cd mobile && flutter build apk --release -t lib/main_prod.dart
	@echo "APK: mobile/build/app/outputs/flutter-apk/app-release.apk"

##@ Docker (local only, not used on the server yet)
docker-build: ## Build the images
	docker compose build

docker-up: ## Start API, worker, beat, Redis and storefront
	docker compose up -d --build
	@echo "Storefront: http://localhost:3000   API docs: http://localhost:8000/api/docs/"

docker-down: ## Stop the containers
	docker compose down

docker-logs: ## Follow container logs
	docker compose logs -f --tail=100

docker-seed: ## Load demo data inside the API container
	docker compose exec api python manage.py seed_demo

##@ Server (VM, override with SSH_TARGET=user@host)
deploy-key: ## Create the GitHub Actions deploy key on the VM and print it (→ DEPLOY_SSH_KEY secret)
	@ssh $(SSH_TARGET) 'set -e; \
	  test -f ~/.ssh/rocket_deploy || ssh-keygen -q -t ed25519 -N "" -C github-actions-rocket -f ~/.ssh/rocket_deploy; \
	  touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; \
	  grep -qxF "$$(cat ~/.ssh/rocket_deploy.pub)" ~/.ssh/authorized_keys || cat ~/.ssh/rocket_deploy.pub >> ~/.ssh/authorized_keys; \
	  cat ~/.ssh/rocket_deploy'

known-hosts: ## Print the VM host key (→ optional DEPLOY_KNOWN_HOSTS secret)
	@ssh-keyscan -H $(lastword $(subst @, ,$(SSH_TARGET))) 2>/dev/null

server-setup: ## One-time VM setup over SSH (nginx, Python, Node, certs, services)
	ssh $(SSH_TARGET) 'rm -rf /tmp/rocket-setup'
	scp -rq deploy $(SSH_TARGET):/tmp/rocket-setup
	ssh -t $(SSH_TARGET) 'sudo bash /tmp/rocket-setup/scripts/server-setup.sh'

ssh: ## Open a shell on the VM
	ssh $(SSH_TARGET)

status: ## Service status on the VM
	ssh $(SSH_TARGET) 'systemctl --no-pager status rocket-api rocket-web | head -n 30; systemctl list-timers "rocket-*" --no-pager'

logs-api: ## Follow API logs on the VM
	ssh $(SSH_TARGET) 'journalctl -u rocket-api -f -n 100'

logs-web: ## Follow storefront logs on the VM
	ssh $(SSH_TARGET) 'journalctl -u rocket-web -f -n 100'

rollback-api: ## Switch the API back to the previous release
	ssh $(SSH_TARGET) 'bash /opt/rocket/deploy/scripts/rollback.sh backend'

rollback-web: ## Switch the storefront back to the previous release
	ssh $(SSH_TARGET) 'bash /opt/rocket/deploy/scripts/rollback.sh storefront'
