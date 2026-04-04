# Movie Finder — DevOps Setup Guide

> **Audience:** DevOps / platform team
> **Scope:** Docker, Azure cloud provisioning, Jenkins CI/CD, GitHub Webhooks
> **Services:** FastAPI backend · Angular frontend · PostgreSQL database · Qdrant Cloud (external)

---

## Table of contents

1. [Architecture overview](#1-architecture-overview)
2. [Docker images and local stack](#2-docker-images-and-local-stack)
3. [CI pipeline modes](#3-ci-pipeline-modes)
4. [Prerequisites](#4-prerequisites)
5. [Azure — provision infrastructure](#5-azure--provision-infrastructure)
6. [Jenkins — install on Ubuntu](#6-jenkins--install-on-ubuntu)
7. [Jenkins — expose via ngrok](#7-jenkins--expose-via-ngrok)
8. [Jenkins — plugins](#8-jenkins--plugins)
9. [Jenkins — credentials](#9-jenkins--credentials)
10. [Jenkins — pipeline jobs](#10-jenkins--pipeline-jobs)
11. [GitHub — webhooks](#11-github--webhooks)
12. [Runtime secrets — Azure Key Vault](#12-runtime-secrets--azure-key-vault)
13. [Verify end-to-end](#13-verify-end-to-end)
14. [Reference tables](#14-reference-tables)

---

## 1. Architecture overview

```
                         ┌─────────────────────────────────┐
                         │   GitHub (movie-finder repo)     │
                         │   Branches: main, feature/*      │
                         │   Tags:     v*                   │
                         └────────────┬────────────────────┘
                                      │ webhook
                         ┌────────────▼────────────────────┐
                         │   Jenkins (Ubuntu + ngrok)       │
                         │   ┌──────────┐ ┌─────────────┐  │
                         │   │ frontend │ │  backend    │  │
                         │   │ pipeline │ │  pipeline   │  │
                         │   └──────────┘ └─────────────┘  │
                         └────────┬──────────────┬──────────┘
                     docker push  │              │ docker push
                         ┌────────▼──────────────▼──────────┐
                         │   Azure Container Registry (ACR)  │
                         │   movie-finder-frontend:sha8      │
                         │   movie-finder-backend:sha8       │
                         └────────┬──────────────┬──────────┘
                     az update    │              │ az update
              ┌──────────────────────────────────────────────────────┐
              │          Azure Container Apps Environment             │
              │                                                       │
              │  ┌───────────────────┐   ┌────────────────────────┐  │
              │  │ movie-finder-     │   │  movie-finder-         │  │
              │  │ frontend[-staging]│◄──│  backend[-staging]     │  │
              │  │  nginx + Angular  │   │  FastAPI + LangGraph   │  │
              │  │  port 80          │   │  port 8000             │  │
              │  └───────────────────┘   └──────────┬─────────────┘  │
              │                                     │                 │
              │                          ┌──────────▼─────────────┐  │
              │                          │  Azure Database for    │  │
              │                          │  PostgreSQL Flexible   │  │
              │                          │  Server (sessions/     │  │
              │                          │  users/messages)       │  │
              │                          └────────────────────────┘  │
              └──────────────────────────────────────────────────────┘

  Secrets:   Azure Key Vault ──► backend Container App (managed identity)
  Vector DB: Qdrant Cloud (external) — no container in any environment
  App DB:    Azure Database for PostgreSQL Flexible Server
```

---

## 2. Docker images and local stack

### 2.1 Image inventory

| Image                   | Base                  | Compressed size | Notes                                                  |
| ----------------------- | --------------------- | --------------- | ------------------------------------------------------ |
| `movie-finder-backend`  | `python:3.13-slim`    | ~280 MB         | uv venv + FastAPI stack                                |
| `movie-finder-frontend` | `nginx:stable-alpine` | ~25 MB          | Angular bundle + nginx                                 |
| `postgres:16-alpine`    | _(official)_          | ~85 MB          | Local dev only; Azure PG Flexible Server in production |

Both application images use **multi-stage builds**:

- Backend: builder (uv + Python deps) → runtime (slim Python, no build tools)
- Frontend: deps (npm cache) → builder (Angular compile) → runner (nginx only, no Node.js)

### 2.2 Build optimizations in place

**Backend (`backend/Dockerfile`):**

- uv version pinned to `0.5` series — reproducible, no surprise upgrades
- `--mount=type=cache,target=/root/.cache/uv` — uv download cache never enters the layer
- `COPY --link` in the runtime stage — BuildKit resolves layers in parallel
- `HEALTHCHECK` uses stdlib `urllib` — no `curl` installation needed in slim image

**Frontend (`frontend/Dockerfile`):**

- `--mount=type=cache,target=/root/.npm` — npm cache never enters the layer
- `node_modules` copied from the `deps` stage, not re-downloaded in `builder`
- Final image is nginx-only — zero Node.js in production

**CI (`backend/Jenkinsfile`, `frontend/Jenkinsfile`):**

- `docker pull :latest || true` before build — seeds the local cache
- `--cache-from :latest` — reuses unchanged layers from the previous push

### 2.3 Local development stack

#### Option A — Full stack (all services together)

```bash
# 1. Clone and initialise submodules
git clone https://github.com/aharbii/movie-finder.git
cd movie-finder
git submodule update --init --recursive

# 2. Create .env from the template and fill in API keys
cp .env.example .env
$EDITOR .env
# Required: DB_PASSWORD, APP_SECRET_KEY, ANTHROPIC_API_KEY, OPENAI_API_KEY,
#           QDRANT_URL, QDRANT_API_KEY_RO (from RAG team after each ingestion run)

# 3. Build and start the full stack
docker compose up --build

# Services
# Frontend:   http://localhost:80
# Backend:    http://localhost:8000
# API docs:   http://localhost:8000/docs
# PostgreSQL: localhost:5432 (app data — users, sessions, messages)
```

The root `docker-compose.yml` wires three services together:

- `postgres` starts first (health-checked with `pg_isready`)
- `backend` waits for postgres healthy, overrides `DATABASE_URL` to reach the compose postgres
- `frontend` waits for backend healthy, sets `BACKEND_URL=http://backend:8000` for nginx proxy

Qdrant is **not** in the compose file — backend and frontend always connect to the production
Qdrant Cloud cluster via `QDRANT_URL` and `QDRANT_API_KEY_RO` from `.env`.

#### Option B — Backend standalone (no full-stack compose needed)

```bash
cd backend/

# Start only PostgreSQL (no Qdrant, no frontend)
make db-start
# → PostgreSQL at localhost:5432, db: movie_finder, user: movie_finder

# If migrating from a previous SQLite dev database
make db-migrate

# Start the dev server (reads .env in backend/)
make run-dev
```

---

## 3. CI pipeline modes

Both the backend and frontend pipelines share the same three-mode design, automatically selected by Git context:

| Mode             | Trigger            | Backend stages                                                          | Frontend stages                                                    |
| ---------------- | ------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **CONTRIBUTION** | Feature branch, PR | Lint (parallel) · Unit tests (parallel)                                 | Type-check                                                         |
| **INTEGRATION**  | Push to `main`     | All above + Build image + Push `:sha8` `:latest` + (opt) Deploy staging | Type-check + Build + Push `:sha8` `:latest` + (opt) Deploy staging |
| **RELEASE**      | Git tag `v*`       | All above + Push `:v1.2.3` + Manual approval → Deploy production        | All above + Push `:v1.2.3` + (opt) Deploy production               |

**CONTRIBUTION** gives developers fast feedback (< 5 min) without spending ACR egress or Azure compute. Nothing is built or pushed.

**INTEGRATION** validates the full build and keeps `movie-finder-{backend,frontend}-staging` always up-to-date with `main`. Staging deploys are automatic on the backend; they require `DEPLOY_STAGING=true` on the frontend (manual opt-in).

**RELEASE** is triggered by pushing a semver tag (`v1.2.3`). The backend requires a human to click **Deploy** in the Jenkins UI (30-minute timeout). The frontend uses `DEPLOY_PRODUCTION=true` parameter.

---

## 4. Prerequisites

Install these on the Jenkins Ubuntu machine and your operator workstation.

| Tool          | Min version | Install                                                   |
| ------------- | ----------- | --------------------------------------------------------- |
| Azure CLI     | 2.60        | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| Docker Engine | 24          | `sudo apt install docker.io`                              |
| Java 21       | 21          | `sudo apt install openjdk-21-jre-headless`                |
| ngrok         | 3.x         | [ngrok.com/download](https://ngrok.com/download)          |
| Git           | 2.x         | `sudo apt install git`                                    |

Log in to Azure before running any `az` commands:

```bash
az login
az account set --subscription "<your-subscription-id>"
```

---

## 5. Azure — provision infrastructure

### 5.1 Backend — automated via provision.sh

The backend team provides a provisioning script that creates all backend Azure resources in one run.

```bash
# Set the secrets the script will store in Key Vault
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export QDRANT_URL="https://your-cluster.qdrant.io"
export QDRANT_API_KEY_RO="..."     # read-only key for chain/app at query time
export APP_SECRET_KEY="$(openssl rand -hex 32)"
# DATABASE_URL is generated by provision.sh from the created PG server credentials

# Run for staging first, then production
chmod +x backend/deploy/provision.sh
./backend/deploy/provision.sh staging
./backend/deploy/provision.sh production
```

The script creates (per environment):

| Resource                                            | Purpose                                            |
| --------------------------------------------------- | -------------------------------------------------- |
| Resource Group `rg-movie-finder-{env}`              | Scope boundary for RBAC and billing                |
| Container Registry `acrmoviefinder`                 | Shared Docker image store (one ACR for both envs)  |
| Key Vault `kv-movie-finder-{env}`                   | Stores all backend runtime secrets                 |
| Azure Database for PostgreSQL Flexible Server       | Relational DB for users, sessions, messages        |
| Log Analytics Workspace                             | Required by Container Apps; enables log queries    |
| Container Apps Environment `cae-movie-finder-{env}` | Shared runtime for all apps                        |
| Container App `ca-movie-finder-{env}`               | Backend FastAPI service (placeholder image)        |
| Managed Identity `id-movie-finder-{env}`            | Pulls images from ACR; reads Key Vault secrets     |
| Service Principal `sp-movie-finder-cicd`            | Jenkins CI/CD — push to ACR, update Container Apps |

> **PostgreSQL:** The `DATABASE_URL` is stored in Key Vault and injected as an env var into the Container App via managed identity. Unlike SQLite, PostgreSQL Flexible Server supports horizontal scaling — `maxReplicas` on the backend Container App can safely exceed 1.

At the end of each run, the script prints all Jenkins credential values. **Copy them immediately and add them to Jenkins before the terminal session ends.**

### 5.2 Frontend — manual steps

The frontend Container App is simpler (no Key Vault, no file shares).

```bash
# Variables (reuse from provision.sh output or set manually)
RG="movie-finder-rg"
ACA_ENV="cae-movie-finder-staging"   # created by provision.sh

# Staging
az containerapp create \
  --name            "movie-finder-frontend-staging" \
  --resource-group  "$RG" \
  --environment     "$ACA_ENV" \
  --image           "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --target-port     80 \
  --ingress         external \
  --min-replicas    1 \
  --max-replicas    3

# Production (use the production ACA environment)
ACA_ENV_PROD="cae-movie-finder-production"
az containerapp create \
  --name            "movie-finder-frontend" \
  --resource-group  "movie-finder-rg-production" \
  --environment     "$ACA_ENV_PROD" \
  --image           "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --target-port     80 \
  --ingress         external \
  --min-replicas    1 \
  --max-replicas    5
```

### 5.3 Wire frontend to backend

After both apps are deployed, set the frontend's `BACKEND_URL` to the backend's internal FQDN:

```bash
# Get the backend FQDN (replace env suffix as needed)
BACKEND_FQDN=$(az containerapp show \
  --name            "ca-movie-finder-staging" \
  --resource-group  "movie-finder-rg-staging" \
  --query           "properties.configuration.ingress.fqdn" -o tsv)

# Staging frontend → staging backend
az containerapp update \
  --name            "movie-finder-frontend-staging" \
  --resource-group  "movie-finder-rg-staging" \
  --set-env-vars    "API_URL=" "BACKEND_URL=https://${BACKEND_FQDN}"

# Production — repeat with production names
```

> **Tip:** `API_URL=""` (empty string) tells the Angular app to use same-origin URLs, so nginx handles all `/auth`, `/chat`, `/health` proxying transparently.

### 5.4 Grant Jenkins SP access to frontend Container Apps

The service principal created by `provision.sh` (`sp-movie-finder-cicd`) has Contributor on the backend resource groups. Grant it the same on the frontend:

```bash
SP_APP_ID="<appId from provision.sh output>"
RG_STAGING="movie-finder-rg-staging"
RG_PROD="movie-finder-rg-production"

az role assignment create --assignee "$SP_APP_ID" --role Contributor \
  --scope "$(az group show --name $RG_STAGING --query id -o tsv)"

az role assignment create --assignee "$SP_APP_ID" --role Contributor \
  --scope "$(az group show --name $RG_PROD --query id -o tsv)"
```

---

## 6. Jenkins — install on Ubuntu

```bash
# Add Jenkins APT repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list

sudo apt update && sudo apt install -y jenkins

# Jenkins needs to run Docker commands (for docker:24-dind builds)
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo systemctl enable jenkins

# Install Azure CLI so the 'deploy' agent label can run az commands
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Initial setup:**

1. Open `http://localhost:8080` in a browser on the Jenkins machine.
2. Paste the unlock password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Select **Install suggested plugins**.
4. Create the admin user.
5. Add the `deploy` label to this agent: **Manage Jenkins → Nodes → Built-In Node → Labels** → add `deploy`.

> The `deploy` label is used by Deploy stages that need `az` CLI. If you later add separate cloud agents for Docker builds, label them `docker` and update the pipeline's `agent { label }` blocks.

---

## 7. Jenkins — expose via ngrok

ngrok provides the public HTTPS URL that GitHub uses to deliver webhook payloads to your local Jenkins instance.

### 7.1 Install and authenticate

```bash
# Download (Linux x86-64; adjust for ARM if needed)
wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar xzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin
rm ngrok-v3-stable-linux-amd64.tgz

# Authenticate (one-time, using your authtoken from ngrok.com)
ngrok config add-authtoken <YOUR_NGROK_AUTHTOKEN>
```

### 7.2 Run as a persistent systemd service

```bash
sudo tee /etc/systemd/system/ngrok.service > /dev/null <<'EOF'
[Unit]
Description=ngrok tunnel for Jenkins
After=network.target

[Service]
ExecStart=/usr/local/bin/ngrok http 8080 --log=stdout
Restart=always
RestartSec=5
User=ubuntu

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now ngrok
```

### 7.3 Get the public URL

```bash
# The ngrok agent API lists active tunnels
curl -s http://localhost:4040/api/tunnels \
  | python3 -c "import sys,json; t=json.load(sys.stdin)['tunnels']; print(t[0]['public_url'])"
```

> **Free plan note:** The public URL changes on every ngrok restart. You will need to update the GitHub webhook URL each time. Use a **paid ngrok plan** with a static domain to avoid this:
>
> ```bash
> # In the systemd service, replace the ExecStart line with:
> ExecStart=/usr/local/bin/ngrok http 8080 --domain=<your-static-domain>.ngrok-free.app --log=stdout
> ```

### 7.4 Configure Jenkins URL

In Jenkins: **Manage Jenkins → System → Jenkins URL** → set to the ngrok HTTPS URL (e.g. `https://abc123.ngrok-free.app`). This is required so GitHub status checks link back to the right build.

---

## 8. Jenkins — plugins

Install via **Manage Jenkins → Plugins → Available plugins**, then restart Jenkins.

| Plugin                      | Purpose                                             |
| --------------------------- | --------------------------------------------------- |
| **Docker Pipeline**         | `agent { docker { image '...' } }` blocks           |
| **Git**                     | Checkout + submodule support                        |
| **GitHub Integration**      | Webhook trigger, PR status reporting                |
| **Credentials Binding**     | `credentials()` in pipeline `environment {}` blocks |
| **Cobertura**               | Coverage report publishing (`cobertura` post step)  |
| **Pipeline: Declarative**   | Usually pre-installed with suggested plugins        |
| **Blue Ocean** _(optional)_ | Visual pipeline UI                                  |

---

## 9. Jenkins — credentials

Navigate to **Manage Jenkins → Credentials → System → Global credentials → Add Credential**.

Secrets are stored encrypted in Jenkins' credential store. The `credentials()` binding automatically redacts them from build logs — never log them manually.

### 9.1 Shared credentials (both pipelines)

These four are used by both the backend and frontend pipelines. Create them once.

#### `acr-login-server` — Secret text

| Field  | Value                                          |
| ------ | ---------------------------------------------- |
| Kind   | **Secret text**                                |
| ID     | `acr-login-server`                             |
| Secret | ACR hostname, e.g. `moviefinderacr.azurecr.io` |

> Copy from `provision.sh` output: **"Credential ID: acr-login-server"**

#### `acr-credentials` — Username with password

Used for `docker login` to ACR.

| Field    | Value                                                 |
| -------- | ----------------------------------------------------- |
| Kind     | **Username with password**                            |
| ID       | `acr-credentials`                                     |
| Username | Service principal App ID (from `provision.sh` output) |
| Password | Service principal client secret                       |

#### `azure-sp` — Username with password

Used for `az login --service-principal` in Deploy stages.

| Field    | Value                          |
| -------- | ------------------------------ |
| Kind     | **Username with password**     |
| ID       | `azure-sp`                     |
| Username | Same SP App ID as above        |
| Password | Same SP client secret as above |

> `acr-credentials` and `azure-sp` hold the same SP credentials — they're separate entries because they serve different tools (`docker login` vs `az login`).

#### `azure-tenant-id` — Secret text

Used by both backend and frontend Deploy stages for `az login`.

| Field  | Value                |
| ------ | -------------------- |
| Kind   | **Secret text**      |
| ID     | `azure-tenant-id`    |
| Secret | Azure AD tenant UUID |

#### `github-ssh-key` — SSH Username with private key

Used by the backend Checkout stage to run `git submodule update --init --recursive`. Add the corresponding public key as a deploy key in all submodule repos (`aharbii/movie-finder-chain`, `aharbii/imdbapi-client`, `aharbii/movie-finder-rag`).

| Field       | Value                                                            |
| ----------- | ---------------------------------------------------------------- |
| Kind        | **SSH Username with private key**                                |
| ID          | `github-ssh-key`                                                 |
| Username    | `git`                                                            |
| Private Key | A deploy key private key with read access to all submodule repos |

### 9.2 Backend-specific credentials

These are only consumed by `backend/Jenkinsfile`.

| Credential ID      | Kind        | Value                                                       |
| ------------------ | ----------- | ----------------------------------------------------------- |
| `azure-sub-id`     | Secret text | Azure subscription ID                                       |
| `aca-rg`           | Secret text | Resource group, e.g. `movie-finder-rg-staging`              |
| `aca-staging-name` | Secret text | Staging Container App, e.g. `ca-movie-finder-staging`       |
| `aca-prod-name`    | Secret text | Production Container App, e.g. `ca-movie-finder-production` |

All four values are printed at the end of `provision.sh`.

### 9.2a Frontend-specific credentials

These are only consumed by `frontend/Jenkinsfile`.

| Credential ID               | Kind        | Value                                  |
| --------------------------- | ----------- | -------------------------------------- |
| `aca-staging-rg`            | Secret text | Frontend staging resource group        |
| `aca-frontend-staging-name` | Secret text | Staging frontend Container App name    |
| `aca-prod-rg`               | Secret text | Frontend production resource group     |
| `aca-frontend-name`         | Secret text | Production frontend Container App name |

### 9.3 GitHub webhook secret _(recommended)_

| Field  | Value                                           |
| ------ | ----------------------------------------------- |
| Kind   | **Secret text**                                 |
| ID     | `github-webhook-secret`                         |
| Secret | Any random string (e.g. `openssl rand -hex 20`) |

Use the same value in **Manage Jenkins → System → GitHub → Shared secret** and in the GitHub webhook configuration (section 11).

### 9.4 Complete credentials reference

| ID                          | Kind            | Used by      | Purpose                                                  |
| --------------------------- | --------------- | ------------ | -------------------------------------------------------- |
| `acr-login-server`          | Secret text     | Both         | ACR hostname for docker login + image tags               |
| `acr-credentials`           | User+Pass       | Both         | `docker login` to ACR                                    |
| `azure-sp`                  | User+Pass       | Both         | `az login` for Container App updates                     |
| `azure-tenant-id`           | Secret text     | Both         | Tenant ID for `az login`                                 |
| `github-ssh-key`            | SSH private key | Backend      | Deploy key for `git submodule update --init --recursive` |
| `azure-sub-id`              | Secret text     | Backend      | Subscription for `az account set`                        |
| `aca-rg`                    | Secret text     | Backend      | Resource group of backend Container Apps                 |
| `aca-staging-name`          | Secret text     | Backend      | Backend staging Container App name                       |
| `aca-prod-name`             | Secret text     | Backend      | Backend production Container App name                    |
| `aca-staging-rg`            | Secret text     | Frontend     | Frontend staging resource group                          |
| `aca-frontend-staging-name` | Secret text     | Frontend     | Frontend staging Container App name                      |
| `aca-prod-rg`               | Secret text     | Frontend     | Frontend production resource group                       |
| `aca-frontend-name`         | Secret text     | Frontend     | Frontend production Container App name                   |
| `github-webhook-secret`     | Secret text     | Jenkins core | Validates webhook signatures                             |

---

## 10. Jenkins — pipeline jobs

Create two **Multibranch Pipeline** jobs — one per service.

### 10.1 Frontend pipeline

1. **New Item → Multibranch Pipeline** → Name: `movie-finder-frontend`
2. **Branch Sources → GitHub**
   - Repository URL: `https://github.com/aharbii/movie-finder.git`
   - Credentials: GitHub PAT (classic, `repo` scope) — add as Username/Password
   - Discover branches: **All branches**
   - Discover tags: **Matching** `v*`
3. **Build Configuration**
   - Mode: **by Jenkinsfile**
   - Script path: `frontend/Jenkinsfile`
4. **Scan Multibranch Pipeline Triggers**
   - Check **Periodically if not otherwise run** → interval: **1 minute** (webhook fallback)
5. **Save** — Jenkins scans the repo and creates branch jobs.

### 10.2 Backend pipeline

Same as above except:

- Name: `movie-finder-backend`
- Script path: `backend/Jenkinsfile`

### 10.3 Agent label requirements

| Label                | Required tools            | Who uses it                 |
| -------------------- | ------------------------- | --------------------------- |
| _(no label)_ / `any` | Git, Docker socket access | Checkout, lint, test stages |
| `deploy`             | Azure CLI (`az`)          | All Deploy stages           |

The built-in Jenkins node satisfies both. If you later add cloud agents for isolation, label them accordingly and ensure `az` is installed on the `deploy`-labelled nodes.

---

## 11. GitHub — webhooks

### 11.1 Add the webhook

1. GitHub → **aharbii/movie-finder** → **Settings → Webhooks → Add webhook**
2. **Payload URL:** `https://<ngrok-url>/github-webhook/`
   _(trailing slash is required by the Jenkins GitHub plugin)_
3. **Content type:** `application/json`
4. **Secret:** the same value stored in `github-webhook-secret` credential (section 9.3)
5. **Events:**
   - [x] Pushes
   - [x] Pull requests
6. **Active:** checked → **Add webhook**

GitHub sends an initial ping — verify it returns HTTP 200 in the webhook's **Recent Deliveries** tab.

### 11.2 Branch protection _(recommended)_

**Settings → Branches → Add rule** for `main`:

- [x] Require status checks to pass before merging
  - Required checks: `Type-check` (frontend), `Lint / Lint — app` (backend)
- [x] Require branches to be up to date
- [x] Do not allow bypassing the above settings

---

## 12. Runtime secrets — Azure Key Vault

Backend secrets (API keys, JWT signing key) are stored in Key Vault and injected at runtime by the Container App's managed identity. They are **never baked into images** and **never passed through Jenkins**.

### 12.1 What's stored in Key Vault

The `provision.sh` script stores these automatically:

| Key Vault secret name | Container App env var |
| --------------------- | --------------------- |
| `APP-SECRET-KEY`      | `APP_SECRET_KEY`      |
| `ANTHROPIC-API-KEY`   | `ANTHROPIC_API_KEY`   |
| `OPENAI-API-KEY`      | `OPENAI_API_KEY`      |
| `QDRANT-URL`          | `QDRANT_URL`          |
| `QDRANT-API-KEY-RO`   | `QDRANT_API_KEY_RO`   |
| `DATABASE-URL`        | `DATABASE_URL`        |

### 12.2 Rotate a secret

```bash
# Update the value in Key Vault
az keyvault secret set \
  --vault-name "kv-movie-finder-staging" \
  --name       "ANTHROPIC-API-KEY" \
  --value      "new-value"

# Container Apps do NOT pick up rotated secrets automatically.
# Trigger a new revision to reload:
az containerapp update \
  --name            "ca-movie-finder-staging" \
  --resource-group  "movie-finder-rg-staging"
```

### 12.3 Frontend has no secrets

The frontend Container App only needs two environment variables — both non-sensitive:

| Variable      | Value                                      |
| ------------- | ------------------------------------------ |
| `API_URL`     | `""` (empty — same-origin via nginx proxy) |
| `BACKEND_URL` | `https://<backend-staging-fqdn>`           |

These are set directly on the Container App (section 5.3), not via Key Vault.

---

## 13. Verify end-to-end

### 13.1 Local stack

```bash
cd movie-finder
git submodule update --init --recursive
cp .env.example .env && $EDITOR .env   # add API keys

docker compose up --build
curl http://localhost:8000/health      # {"status":"ok"}
open http://localhost:80               # Angular SPA
```

### 13.2 Trigger a CONTRIBUTION build

```bash
git checkout -b test/ci-smoke
git commit --allow-empty -m "chore: trigger CI smoke"
git push origin test/ci-smoke
```

Expected in Jenkins:

- Webhook received (HTTP 200 in GitHub webhook deliveries)
- **Frontend** job: only `Type-check` runs → green
- **Backend** job: `Lint` (parallel, 3 sub-stages) + `Test` (parallel, 4 sub-stages) → green
- No images pushed, no Azure resources touched

### 13.3 Trigger an INTEGRATION build

```bash
git checkout main
git merge test/ci-smoke
git push origin main
```

Expected:

- Both pipelines run all stages
- Images pushed to ACR: `:sha8` and `:latest`
- Backend staging Container App updated automatically
- Frontend staging deploy requires `DEPLOY_STAGING=true` parameter (manual)

### 13.4 Cut a RELEASE

```bash
git tag v1.0.0 -m "First release"
git push origin v1.0.0
```

Expected:

- Both pipelines run all stages
- Images tagged `:v1.0.0` pushed to ACR
- Backend: Jenkins UI shows **"Deploy v1.0.0 to PRODUCTION?"** — click **Deploy** within 30 minutes
- Frontend: re-run the tag build with `DEPLOY_PRODUCTION=true` checked

### 13.5 Verify Azure deployment

```bash
# Get backend FQDN
FQDN=$(az containerapp show \
  --name ca-movie-finder-staging \
  --resource-group movie-finder-rg-staging \
  --query "properties.configuration.ingress.fqdn" -o tsv)

curl https://$FQDN/health        # {"status":"ok"}
curl https://$FQDN/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## 14. Reference tables

### 14.1 Jenkins pipeline job summary

| Job name                | Jenkinsfile path       | Repo URL                                      |
| ----------------------- | ---------------------- | --------------------------------------------- |
| `movie-finder-frontend` | `frontend/Jenkinsfile` | `https://github.com/aharbii/movie-finder.git` |
| `movie-finder-backend`  | `backend/Jenkinsfile`  | `https://github.com/aharbii/movie-finder.git` |

### 14.2 Azure Container Apps

| Container App                   | Image                        | Env        | Replicas     | Port |
| ------------------------------- | ---------------------------- | ---------- | ------------ | ---- |
| `ca-movie-finder-staging`       | `movie-finder-backend:sha8`  | staging    | min=0, max=2 | 8000 |
| `ca-movie-finder-production`    | `movie-finder-backend:v*`    | production | min=1, max=4 | 8000 |
| `movie-finder-frontend-staging` | `movie-finder-frontend:sha8` | staging    | min=1, max=3 | 80   |
| `movie-finder-frontend`         | `movie-finder-frontend:v*`   | production | min=1, max=5 | 80   |

> Backend replicas are no longer capped at 1 — PostgreSQL supports concurrent connections from multiple replicas. Scale as needed based on load.

### 14.3 Backend Container App environment variables

| Variable                 | Source    | Notes                                          |
| ------------------------ | --------- | ---------------------------------------------- |
| `APP_ENV`                | Inline    | `staging` or `production`                      |
| `APP_PORT`               | Inline    | `8000`                                         |
| `QDRANT_COLLECTION_NAME` | Inline    | `movies`                                       |
| `EMBEDDING_MODEL`        | Inline    | `text-embedding-3-large`                       |
| `EMBEDDING_DIMENSION`    | Inline    | `3072`                                         |
| `RAG_TOP_K`              | Inline    | `8`                                            |
| `MAX_REFINEMENTS`        | Inline    | `3`                                            |
| `IMDB_SEARCH_LIMIT`      | Inline    | `3` (imdbapi.dev requires no API key)          |
| `CONFIDENCE_THRESHOLD`   | Inline    | `0.3`                                          |
| `LOG_LEVEL`              | Inline    | `INFO`                                         |
| `LANGSMITH_TRACING`      | Inline    | `false` (enable for debugging)                 |
| `APP_SECRET_KEY`         | Key Vault | JWT signing key                                |
| `DATABASE_URL`           | Key Vault | `postgresql://user:pass@pg-server:5432/dbname` |
| `ANTHROPIC_API_KEY`      | Key Vault | Claude models                                  |
| `OPENAI_API_KEY`         | Key Vault | OpenAI embeddings                              |
| `QDRANT_URL`             | Key Vault | Qdrant Cloud cluster URL                       |
| `QDRANT_API_KEY_RO`      | Key Vault | Qdrant read-only API key (runtime)             |

### 14.4 Docker image tag strategy

| Tag                        | When pushed                   | Deployed to                                           |
| -------------------------- | ----------------------------- | ----------------------------------------------------- |
| `:sha8` (e.g. `:a1b2c3d4`) | Every `main` push + every tag | Staging (auto for backend, manual for frontend)       |
| `:latest`                  | Every `main` push             | Never deployed directly — used as `--cache-from` seed |
| `:v1.2.3`                  | Every `v*` tag                | Production (after approval)                           |

Images are always deployed by the **immutable `:sha8`** tag. `:latest` exists only as a layer cache seed for CI builds — never reference it in `az containerapp update`.

### 14.5 Troubleshooting

| Symptom                     | Likely cause                   | Fix                                                     |
| --------------------------- | ------------------------------ | ------------------------------------------------------- |
| Webhook not received        | ngrok URL changed              | Get new URL via `/api/tunnels`, update GitHub webhook   |
| `docker login` fails        | `acr-credentials` wrong        | Verify SP App ID + secret in Jenkins credentials        |
| `az login` fails            | `azure-sp` wrong or SP expired | Re-create SP with `provision.sh`, update Jenkins        |
| Backend 500 on startup      | Missing Key Vault secret       | Check `az keyvault secret list --vault-name kv-...`     |
| Backend can't reach DB      | `DATABASE_URL` wrong           | Verify Key Vault secret; check PG server firewall rules |
| Frontend shows blank page   | `BACKEND_URL` wrong            | Update with `az containerapp update --set-env-vars`     |
| PG connection refused in CI | postgres sidecar not ready     | Check `pg_isready` loop in Test — app Jenkinsfile stage |
| Build takes 10+ min         | No `--cache-from` layer hit    | Ensure `:latest` was pushed and ACR is accessible       |
