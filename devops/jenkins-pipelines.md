# Jenkins CI Pipelines — Reference Guide

> **Audience:** Developer or DevOps setting up CI for the first time, or diagnosing a failing check.
> **Scope:** All five repo pipelines, pipeline mode differentiation, GitHub rulesets + status check
> context names.

---

## Which repos have CI pipelines

| Repo                    | Jenkinsfile location        | Image published to ACR?           | Pipeline type                                       |
| ----------------------- | --------------------------- | --------------------------------- | --------------------------------------------------- |
| `movie-finder-backend`  | `backend/Jenkinsfile`       | **Yes** — `movie-finder-backend`  | Multibranch — CONTRIBUTION / INTEGRATION / RELEASE  |
| `movie-finder-frontend` | `frontend/Jenkinsfile`      | **Yes** — `movie-finder-frontend` | Multibranch — CONTRIBUTION / INTEGRATION / RELEASE  |
| `movie-finder-chain`    | `chain/Jenkinsfile`         | No — internal library             | Multibranch — PR validation + Dockerfile smoke      |
| `imdbapi-client`        | `imdbapi/Jenkinsfile`       | No — internal library             | Multibranch — PR validation + Dockerfile smoke      |
| `movie-finder-rag`      | `rag_ingestion/Jenkinsfile` | No — offline tool                 | Multibranch — PR validation + manual ingest trigger |

---

## How Jenkins Multibranch Pipeline discovers builds

```
GitHub pushes webhook ──► Jenkins ──► Multibranch Pipeline job
                                           │
              ┌────────────────────────────┤
              │                            │
              ▼                            ▼
         Branch build               Pull Request build
      (BRANCH_NAME = "main")        (CHANGE_ID = "42")
      (BRANCH_NAME = "feature/x")   (BRANCH_NAME = "PR-42")
              │                            │
         Runs all stages            Runs all stages EXCEPT
         without when {}            those with when { branch 'main' }
         restrictions               or when { buildingTag() }
```

Jenkins automatically discovers branches and open PRs via the **GitHub Branch Source** plugin.
Each branch or PR becomes a child job inside the Multibranch job:

| Child job name     | Trigger                | When created        |
| ------------------ | ---------------------- | ------------------- |
| `main`             | Push to `main`         | Always exists       |
| `feature/my-thing` | Push to feature branch | While branch exists |
| `PR-42`            | PR opened or updated   | While PR is open    |
| `v1.2.3`           | Tag `v1.2.3` pushed    | Once per tag        |

---

## Pipeline mode differentiation in Jenkinsfiles

Each Jenkinsfile uses `when {}` conditions to select which stages run:

```groovy
// Runs on EVERY build (PR, branch, tag):
stage('Lint + Typecheck') { ... }
stage('Test') { ... }

// Runs only on main branch pushes (INTEGRATION mode):
stage('Build & Push Image') {
    when { branch 'main' }
    ...
}

// Runs only on version tags v* (RELEASE mode):
stage('Deploy to Production') {
    when { buildingTag() }
    ...
}

// Runs only when manually triggered with the parameter set (rag only):
stage('Ingest') {
    when { expression { params.RUN_INGESTION == true } }
    ...
}
```

**Summary:**

| What triggered the build | `env.BRANCH_NAME`           | `buildingTag()` | `env.CHANGE_ID` |
| ------------------------ | --------------------------- | --------------- | --------------- |
| PR opened / updated      | `PR-N`                      | `false`         | `N` (PR number) |
| Push to feature branch   | branch name                 | `false`         | _(not set)_     |
| Push to `main`           | `main`                      | `false`         | _(not set)_     |
| Tag `v1.2.3` pushed      | _(tag name)_                | `true`          | _(not set)_     |
| "Build with Parameters"  | whatever branch is selected | as above        | _(not set)_     |

So a stage guarded by `when { branch 'main' }` runs for main-branch pushes but **not** for PR builds
even if the PR targets `main`. This is the correct behaviour — you don't want to push an image
before the PR is merged.

---

## How to find the Jenkins status check context name

When Jenkins reports a build result to GitHub (success/failure/pending), it attaches a **context
name** to the commit status. This is what you must enter in the GitHub ruleset "Required status
checks" field.

### Step 1 — open a PR and wait for the build

Open any PR. Jenkins picks it up via the webhook and starts a build. After the build completes,
go to the PR in GitHub → **Checks** tab (or the ✓ / ✗ status icon next to the latest commit).

### Step 2 — read the context name

You will see entries like:

```
continuous-integration/jenkins/pr-merge   ← whole-pipeline status
OR
movie-finder-backend / PR validation      ← per-stage status (if configured)
```

The exact format depends on the Jenkins plugins installed and their configuration. The default with
the **GitHub Branch Source** plugin (used by Multibranch Pipelines) is:

```
continuous-integration/jenkins/pr-merge
continuous-integration/jenkins/branch
```

### Step 3 — copy it into the ruleset

GitHub → repo **Settings → Branches → Rulesets** (or **Branch protection rules** if not using
rulesets) → **Require status checks to pass** → type the context name exactly as shown in the
Checks tab.

> **Tip:** After the first successful build, the GitHub context picker shows a dropdown of
> previously-reported context names. This is the most reliable way to get the exact string.

---

## GitHub rulesets — per-repo configuration

Each repo has its own GitHub ruleset (already configured for `main`). To add CI status checks:

1. Go to **GitHub → repo → Settings → Branches** (or **Rules** → **Rulesets**)
2. Click the existing `main-branch-protection` ruleset
3. Under **Require status checks to pass before merging**, click **Add checks**
4. Search for the context name you found in Step 2 above
5. Enable **Require branches to be up to date before merging**
6. Save

### Per-repo expected context names (approximate — verify after first build)

| Repo                    | Expected context name                     |
| ----------------------- | ----------------------------------------- |
| `movie-finder-backend`  | `continuous-integration/jenkins/pr-merge` |
| `movie-finder-frontend` | `continuous-integration/jenkins/pr-merge` |
| `movie-finder-chain`    | `continuous-integration/jenkins/pr-merge` |
| `imdbapi-client`        | `continuous-integration/jenkins/pr-merge` |
| `movie-finder-rag`      | `continuous-integration/jenkins/pr-merge` |

> These are defaults. If you have customized `githubNotify()` calls in the Jenkinsfile or use a
> non-default GitHub Branch Source configuration, the actual context name will differ. Always
> verify from a live PR's Checks tab — do not guess.

---

## Adding child-repo Multibranch Pipeline jobs in Jenkins

The existing `setup.md` covers the backend and frontend jobs. The three child repos need their
own Multibranch Pipeline jobs:

### movie-finder-chain

1. **New Item → Multibranch Pipeline** → Name: `movie-finder-chain`
2. **Branch Sources → GitHub**
   - Repository URL: `https://github.com/aharbii/movie-finder-chain.git`
   - Credentials: GitHub PAT (same credential used for backend/frontend)
   - Discover branches: **All branches**
   - Discover pull requests: **Merging the pull request with the current target branch revision**
3. **Build Configuration → Script path:** `Jenkinsfile`
4. **Scan Multibranch Pipeline Triggers → Periodically:** 1 minute (webhook fallback)
5. **Save**

### imdbapi-client

Same as chain except:

- Name: `imdbapi-client`
- Repository URL: `https://github.com/aharbii/imdbapi-client.git`
- Script path: `Jenkinsfile`

### movie-finder-rag

Same as chain except:

- Name: `movie-finder-rag`
- Repository URL: `https://github.com/aharbii/movie-finder-rag.git`
- Script path: `Jenkinsfile`

### Webhook setup for child repos

Add a webhook to each child repo (same process as the backend/frontend repos in section 11 of
`setup.md`):

1. GitHub → child repo → **Settings → Webhooks → Add webhook**
2. **Payload URL:** `https://<ngrok-url>/github-webhook/`
3. **Content type:** `application/json`
4. **Events:** Pushes + Pull requests
5. **Active:** checked

---

## Triggering the rag manual ingest

The rag pipeline has a manual ingest stage that only runs when `RUN_INGESTION=true`.

To trigger:

1. Go to Jenkins → `movie-finder-rag` → `main` child job
2. Click **Build with Parameters**
3. Set `RUN_INGESTION` = `true`
4. Set `COLLECTION_NAME` = `movies` (or a custom name for testing)
5. Click **Build**

The pipeline runs lint + typecheck + test first, then runs the ingestion against Qdrant Cloud
if all checks pass.

> **Required credentials:** `qdrant-url`, `qdrant-api-key-rw`, `openai-api-key`,
> `kaggle-api-token` must be present in Jenkins. See `setup.md` section 9.

---

## Troubleshooting

### Build not triggered on PR open

- Check the webhook delivery in GitHub → repo → Settings → Webhooks → Recent Deliveries
- Verify the ngrok URL is still active (`systemctl status ngrok`)
- Check Jenkins → `Manage Jenkins → GitHub → Reregister all hooks`

### Status check not appearing in GitHub PR

- The Multibranch Pipeline job must have completed at least once for the context name to exist
  in GitHub's status check database
- Ensure the **GitHub Branch Source** plugin is installed: `Manage Jenkins → Plugins`
- Check the `githubNotify` or `setBuildStatus` calls in the Jenkinsfile

### "Required status checks" not in ruleset dropdown

GitHub only shows context names that have been previously reported to that repo. Trigger a build
first, then add the check to the ruleset.

### `make init` fails in CI

- Jenkins agent must have Docker socket access: `ls -la /var/run/docker.sock`
- The agent must be in the `docker` group: `groups jenkins`
- Add the Jenkins user to docker group: `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins`
