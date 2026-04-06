# ADR-005: GitHub Actions CI Mirror and Centralised Root Build Pipeline

**Date:** 2026-04-06
**Status:** Accepted

---

## Context

Each submodule had a per-repo Jenkins pipeline that included a "Build App Image" stage.
This caused two problems:

1. **Hanging builds**: the Docker build stage in the internal Jenkins pipelines occasionally
   blocked indefinitely, requiring manual termination, with no automatic failure reporting.
2. **Duplicate builds**: both the backend and frontend pipelines built and pushed images
   independently, with no coordination between them. The root `movie-finder` repo had no
   pipeline at all.

Additionally, all per-repo pipelines were Jenkins-only with no GitHub Actions fallback.
This created a single point of failure: if Jenkins was down or the ngrok tunnel dropped,
the CI system had no secondary path.

---

## Decision

### 1. Remove Build App Image from per-repo pipelines

The `Build App Image` stage is removed from every per-repo Jenkinsfile and GitHub Actions
workflow (`movie-finder-backend`, `movie-finder-frontend`, `movie-finder-chain`,
`imdbapi-client`, `movie-finder-rag`). Per-repo CI is restricted to:

- `Lint` + `Typecheck` + `Test` + `Coverage` — runs on every branch and PR
- No image build, no registry push, no Azure deploy at the per-repo level

### 2. Root pipeline owns build and deploy

A new root-level `movie-finder/Jenkinsfile` and `movie-finder/.github/workflows/ci.yml`
orchestrate the full release path:

```
Checkout submodules
  → Resolve Tag (git tag or sha8)
  → Build Images (parallel: backend + frontend)
      → Push to Azure Container Registry
  → Deploy to Staging (automated)
  → Production Gate (Jenkins: manual input; GitHub Actions: Environment approval)
  → Deploy to Production
```

### 3. GitHub Actions mirrors Jenkins 1:1

Every per-repo and root Jenkins stage has a 1:1 GitHub Actions equivalent. Jenkins remains
the primary CI/CD system; GitHub Actions is the secondary path used for PRs from forks,
GitHub Environment-gated production deploys, and as a fallback during Jenkins outages.

### 4. Reporting plugins standardised

All GitHub Actions workflows use:
- `EnricoMi/publish-unit-test-result-action@v2` (JUnit XML → PR check)
- `irongut/CodeCoverageSummary@v1.3.0` (Cobertura XML → PR comment)
- `marocchino/sticky-pull-request-comment@v2` (sticky comment, not duplicate)

---

## Consequences

**Positive:**
- No more hanging builds: the Docker build stage runs only in the root pipeline where it
  can be properly monitored and timed out.
- Atomic releases: backend and frontend images are always built in the same pipeline run
  with the same tag, preventing image version skew.
- GitHub Actions provides a secondary CI path and richer PR feedback (test + coverage reports).

**Negative:**
- Developers can no longer trigger image builds from a submodule pipeline directly.
  They must push to main or open a PR against the root repo to trigger a build.
- The root pipeline depends on submodule pointers being up to date; pointer drift can
  cause a build to include stale submodule code.

---

## Migration notes

- Per-repo CONTRIBUTION mode (lint + test) is unchanged — developers still get fast
  feedback from their submodule's own pipeline.
- The new `reports/` directory convention (test outputs written to `reports/` inside the
  container) is required for the reporting plugins to locate JUnit and Cobertura XML.
