---
title: "ADR-002: Docker-Only Developer Contract — Standardised Makefile Targets Across All Python Sub-repos"
description: Rationale for the Docker-only local workflow, exec_or_run pattern, and consistent Makefile target set adopted across all Python sub-repos
---

# ADR-002: Docker-Only Developer Contract — Standardised Makefile Targets Across All Python Sub-repos

**Date:** 2026-Q1
**Status:** Accepted

---

## Context

Movie Finder has five Python repos: `movie-finder-backend`, `movie-finder-chain`,
`imdbapi-client`, `movie-finder-rag`, and (root-level orchestration). Each repo
originally evolved its own local development workflow independently, resulting in
several pain points discovered during a developer experience audit in 2026-Q1:

1. **No host Python required, but no consistent contract** — some repos told developers
   to `pip install` locally; others used Docker; documentation was inconsistent.
2. **`make lint` rebuilt the full container** even when a dev container was already running,
   adding 20–40 seconds of startup overhead on every interactive quality check.
3. **`make check` ran tests without coverage** — CI produced coverage XML but local dev did not.
4. **`make init` was inconsistent** — some repos copied `.env.example → .env`; others did not;
   git pre-commit hooks were documented but never installed automatically.
5. **No `make fix` target** — ruff provides auto-fix (`--fix`), but developers had to remember the
   raw command rather than having a standard target.
6. **`make pre-commit` was not wired to `git commit`** — the hook existed as a Makefile target
   but was not installed in `.git/hooks/pre-commit`, so it was never actually enforced.
7. **Chain Dockerfile downloaded oh-my-zsh at build time** — this broke builds in offline/restricted
   environments and added several minutes to fresh image builds.

---

## Decision

### 1. Docker-only: no host Python, no host Node, no host uv

All developer commands execute inside Docker containers. Developers only need Docker + make
(and npm for the frontend). No language runtimes are installed on the host.

### 2. Standardised `exec_or_run` pattern

Every Makefile that runs quality commands (`lint`, `format`, `fix`, `typecheck`, `test`,
`test-coverage`, `pre-commit`, `detect-secrets`) uses the `exec_or_run` macro:

```makefile
define exec_or_run
    @if $(COMPOSE) ps --services --status running 2>/dev/null | grep -qx "$(SERVICE)"; then \
        $(COMPOSE) exec $(SERVICE) $(1); \
    else \
        $(COMPOSE) run --rm --no-deps $(SERVICE) $(1); \
    fi
endef
```

- When the editor container is running (`make editor-up`): uses `docker compose exec` —
  no container startup overhead, interactive dev feels instant.
- When no container is running (CI, first run): falls back to `docker compose run --rm`.
- No `--build` flag on any quality command — image must be built explicitly via `make init`.

### 3. Standardised `make init` behaviour

`make init` in every Python repo:

1. Copies `.env.example → .env` if `.env` does not already exist.
2. Builds the dev Docker image (`docker compose build <service>`).
3. Installs a host-side git pre-commit hook that calls `make pre-commit` on every commit.

The hook is written to `$(git rev-parse --git-dir)/hooks/pre-commit`. This works for both
standalone checkouts and submodule checkouts because `git rev-parse --git-dir` always returns
the correct `.git` path regardless of nesting.

### 4. Standard target set

Every Python repo exposes the same target vocabulary:

| Target                | What it does                                                   |
| --------------------- | -------------------------------------------------------------- |
| `make init`           | Build image, copy `.env`, install git hook                     |
| `make editor-up`      | Start dev container for VS Code attach                         |
| `make editor-down`    | Stop dev container                                             |
| `make shell`          | Open bash shell in container                                   |
| `make lint`           | `ruff check` — report only, no modifications                   |
| `make fix`            | `ruff check --fix` + `ruff format` — auto-apply all safe fixes |
| `make format`         | `ruff format` — format only                                    |
| `make typecheck`      | `mypy` (strict)                                                |
| `make test`           | `pytest`                                                       |
| `make test-coverage`  | `pytest` with XML + HTML + JUnit coverage output               |
| `make detect-secrets` | `detect-secrets scan --baseline .secrets.baseline`             |
| `make pre-commit`     | Full hook suite (runs on `git commit` via installed hook)      |
| `make check`          | `lint` + `typecheck` + `test-coverage` — CI gate               |
| `make ci-down`        | Full teardown with volume + image removal for CI cleanup       |

### 5. Lean dev Dockerfiles

Dev images include only what the attached-container workflow needs:
`git`, `zsh`, `make`, `curl`. Heavy tooling (oh-my-zsh, build-essential, vim, jq) is excluded.
Shell prompt is configured inline — no internet downloads at build time.

### 6. Structurizr via Docker Compose profile

The Structurizr architecture viewer is merged into the main `docker-compose.yml` under a
`docs` profile instead of a separate `docker-compose.docs.yml`:

```bash
docker compose --profile docs up structurizr   # → http://localhost:18080
```

Port 18080 avoids conflicts with Jenkins (8080) and FastAPI (8000).

---

## Consequences

**Positive:**

- Consistent onboarding: `make init && make editor-up` works in every Python repo.
- Interactive dev is fast: `make lint`/`make check` use `docker compose exec` and complete
  in under 2 seconds when the editor container is running.
- git pre-commit hook is automatically installed — `detect-secrets`, `mypy`, `ruff` run on
  every commit with no extra steps.
- CI images are lean — fresh chain image build time dropped from ~4 min to ~90 sec.
- Single compose file — no `-f docker-compose.docs.yml` to remember.

**Negative:**

- Docker must be running for any developer command, including `make lint`. Developers cannot
  run quality checks without Docker.
- `make fix` modifies files in-place — developers must stage the resulting changes before
  committing. This is expected ruff behaviour but may surprise newcomers.

---

## Alternatives considered

- **uv run directly on host** — rejected because it requires per-developer Python version management
  and breaks if uv is not installed or the wrong version is active.
- **GitHub Actions for CI instead of Jenkins** — noted as future direction in ADR-001; out of scope
  for this change, which focuses on local DX.
- **Keeping `docker-compose.docs.yml` separate** — rejected to reduce cognitive overhead; the `docs`
  profile approach is equally explicit (`--profile docs`) and keeps everything in one file.
