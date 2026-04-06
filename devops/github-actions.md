---
title: GitHub Actions CI
description: GitHub Actions CI setup and pipeline reference for Movie Finder
---

# GitHub Actions CI

GitHub Actions mirrors the Jenkins CI setup 1:1. Both run the same quality gates; the root pipeline
builds Docker images and deploys to Azure through GitHub Environments for a manual production gate.

See [ADR-0005: GitHub Actions mirror](../architecture/decisions/0005-github-actions-mirror-and-root-pipeline.md) for the
decision record behind this dual-CI approach.

---

## Workflow inventory

| Repo                          | Workflow file                        | Trigger                    | Purpose                                      |
| ----------------------------- | ------------------------------------ | -------------------------- | -------------------------------------------- |
| `movie-finder-backend`        | `.github/workflows/ci.yml`           | push, pull_request         | CONTRIBUTION: lint + test + coverage         |
| `movie-finder-frontend`       | `.github/workflows/ci.yml`           | push, pull_request         | CONTRIBUTION: lint + typecheck + test        |
| `movie-finder-chain`          | `.github/workflows/ci.yml`           | push, pull_request         | CONTRIBUTION: lint + typecheck + test        |
| `imdbapi-client`              | `.github/workflows/ci.yml`           | push, pull_request         | CONTRIBUTION: lint + typecheck + test        |
| `movie-finder-rag`            | `.github/workflows/ci.yml`           | push, pull_request         | CONTRIBUTION: lint + typecheck + test        |
| `movie-finder` (root)         | `.github/workflows/ci.yml`           | push to main, tags         | INTEGRATION + RELEASE: build + push + deploy |
| `movie-finder-infrastructure` | `.github/workflows/ci.yml`           | push, pull_request         | Terraform validate + TFLint                  |

---

## Pipeline modes

Each per-repo workflow selects its mode based on the Git event:

| Mode             | Trigger                     | Stages                                                              |
| ---------------- | --------------------------- | ------------------------------------------------------------------- |
| **CONTRIBUTION** | Any branch / PR             | Lint · Type-check · Test · Coverage report                          |
| **INTEGRATION**  | Push to `main`              | All above + Build Docker image + Push `:sha8` + `:latest` to ACR   |
| **RELEASE**      | `v*` tag                    | All above + Push `:v1.2.3` + Deploy to production (manual approval) |

CONTRIBUTION builds run on every PR — no images are built or pushed, giving fast feedback.

INTEGRATION builds push images to ACR and update the staging Container Apps automatically.

RELEASE builds require a human approver in a **GitHub Environment** (`production`) before deployment proceeds.

---

## Required secrets

Configure these in **GitHub → repo → Settings → Secrets and variables → Actions**.

### Per-repo CONTRIBUTION secrets (backend, chain, imdbapi, rag)

| Secret name        | Value                                          |
| ------------------ | ---------------------------------------------- |
| `QDRANT_URL`       | Qdrant Cloud cluster URL (read-only for tests) |
| `QDRANT_API_KEY_RO`| Qdrant read-only API key                       |

### Root pipeline INTEGRATION / RELEASE secrets

| Secret name           | Value                                        |
| --------------------- | -------------------------------------------- |
| `ACR_LOGIN_SERVER`    | ACR hostname, e.g. `moviefinderacr.azurecr.io` |
| `ACR_USERNAME`        | Service principal App ID                     |
| `ACR_PASSWORD`        | Service principal client secret              |
| `AZURE_CLIENT_ID`     | Service principal App ID                     |
| `AZURE_CLIENT_SECRET` | Service principal client secret              |
| `AZURE_TENANT_ID`     | Azure AD tenant UUID                         |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID                      |
| `ACA_RG`              | Backend Container App resource group         |
| `ACA_BACKEND_NAME`    | Backend production Container App name        |
| `ACA_FRONTEND_NAME`   | Frontend production Container App name       |

These are the same credentials used in Jenkins (sections 9.1 and 9.2 of the [DevOps setup guide](setup.md)).

---

## GitHub Environments

The root pipeline uses GitHub Environments to gate production deployments.

### Setup

1. Go to **Settings → Environments → New environment**
2. Create an environment named `production`
3. Under **Deployment protection rules**, add **Required reviewers** (yourself or the team)
4. Optionally restrict to the `main` branch only

When a `v*` tag build reaches the Deploy step, GitHub pauses and sends a review request.
The deployer must approve before `az containerapp update` runs.

---

## Status checks for branch protection

After the first successful CI run on a PR, GitHub records the check name. Add it to the branch
ruleset:

1. **Settings → Rules → Rulesets → main-branch-protection**
2. Under **Require status checks**, click **Add checks**
3. Search for the check names that appeared on the PR

Default check names from the committed workflows:

| Repo                    | Check name          |
| ----------------------- | ------------------- |
| `movie-finder-backend`  | `lint` / `test`     |
| `movie-finder-frontend` | `lint` / `test`     |
| `movie-finder-chain`    | `lint` / `test`     |
| `imdbapi-client`        | `lint` / `test`     |
| `movie-finder-rag`      | `lint` / `test`     |

> Verify the exact names from a live PR's **Checks** tab — do not rely on this table if you have
> customised the workflow job names.

---

## Caching strategy

All workflows use GitHub Actions cache to speed up builds:

| Ecosystem | Cache key                    | What is cached                     |
| --------- | ---------------------------- | ---------------------------------- |
| Python    | `uv.lock` hash               | uv download cache (`~/.cache/uv`)  |
| Node.js   | `package-lock.json` hash     | npm cache (`~/.npm`)               |
| Docker    | `ghcr.io` layer cache        | BuildKit layer cache via `--cache-from` |

---

## Troubleshooting

| Symptom                             | Likely cause                          | Fix                                                              |
| ----------------------------------- | ------------------------------------- | ---------------------------------------------------------------- |
| Workflow not triggered on PR        | Branch filter wrong in workflow file  | Check `on: pull_request: branches:` in `.github/workflows/ci.yml` |
| `az login` fails in deploy step     | Secret expired or wrong               | Re-create service principal, update secrets                      |
| Docker push 401                     | `ACR_USERNAME`/`ACR_PASSWORD` wrong   | Verify SP credentials in Azure, update secrets                   |
| Production gate never appears       | `production` environment not created  | Create environment in repo Settings                              |
| Coverage report missing on PR       | `GITHUB_TOKEN` permissions wrong      | Ensure workflow has `pull-requests: write` permission            |
