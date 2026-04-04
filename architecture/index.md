---
title: Architecture
description: Movie Finder system architecture — C4 model, PlantUML diagrams, and architecture decision records
---

# Architecture

This section documents the Movie Finder architecture at multiple levels of detail.

| File / Section                                                                                       | Format               | Purpose                                                        |
| ---------------------------------------------------------------------------------------------------- | -------------------- | -------------------------------------------------------------- |
| [`workspace.dsl`](https://github.com/aharbii/movie-finder-docs/blob/main/architecture/workspace.dsl) | Structurizr DSL (C4) | L1 System Context · L2 Containers · L3 Components · Deployment |
| [PlantUML Diagrams](plantuml/index.md)                                                               | PlantUML (`.puml`)   | Class · Component · Sequence · State · Deployment diagrams     |
| [`decisions/`](decisions/index.md)                                                                   | Markdown ADRs        | Architecture decision records                                  |

---

## Diagram tooling — why three tools

| Tool            | Files                          | Purpose                                                                           | When to edit                                                                 |
| --------------- | ------------------------------ | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **PlantUML**    | `architecture/plantuml/*.puml` | Canonical UML: class, component, sequence, state, deployment                      | Every architectural change — these are the source of truth                   |
| **Structurizr** | `architecture/workspace.dsl`   | C4 model (L1–L3 + deployment views) for stakeholder-facing architecture overviews | When containers, components, or external systems are added or renamed        |
| **StarUML**     | Not in the repo                | Stakeholder export format — never generated programmatically                      | Maintained manually by the project owner from the `.puml` and `.dsl` sources |

PlantUML and Structurizr are both committed as source. StarUML is a manual export used for offline stakeholder reviews; **never commit `.mdj` files**.

---

## How to view diagrams

=== "Full documentation site (recommended)"

    ```bash
    # from repo root — builds everything including PlantUML PNGs and serves MkDocs
    make mkdocs
    # → http://localhost:8001
    ```

=== "PlantUML — VS Code live preview"

    Open any `.puml` file and press `Option+D` / `Alt+D`
    (requires the **jebbs.plantuml** extension, pre-configured in `.vscode/settings.json`).

=== "Structurizr — C4 viewer"

    ```bash
    # from repo root
    make structurizr
    # → http://localhost:18080
    ```

    Navigate between: **System Context · Containers · Components · Deployment (Azure / Local)**

---

## System context (L1)

```
                    ┌───────────────────────────────────────────┐
                    │          Movie Finder System               │
                    │                                           │
User ──────────────►│  Angular SPA  ←→  FastAPI Backend         │
(web browser)       │                        │                  │
                    │               ┌────────┼────────┐         │
                    │               │        │        │         │
                    └───────────────┼────────┼────────┼─────────┘
                                    │        │        │
                               Qdrant   Anthropic  OpenAI
                               Cloud    Claude API Embeddings
                                    │
                               imdbapi.dev
```

| External System  | Purpose                                              | Auth             |
| ---------------- | ---------------------------------------------------- | ---------------- |
| Qdrant Cloud     | Vector similarity search over movie corpus           | API key          |
| Anthropic Claude | Haiku: classification · Sonnet: refinement + Q&A     | API key          |
| OpenAI           | `text-embedding-3-large` at query time and ingestion | API key          |
| imdbapi.dev      | Live IMDb metadata — ratings, posters, credits       | None             |
| Azure Key Vault  | Runtime secrets via managed identity                 | Managed identity |

---

## Container diagram (L2)

```
┌──────────────────────────────────────────────────────────────────────┐
│                       Movie Finder System                             │
│                                                                       │
│  ┌─────────────────┐          ┌──────────────────────────────────┐   │
│  │  Angular SPA     │  REST    │       FastAPI Backend             │   │
│  │  TypeScript 5.9  ├─────────►  Python 3.13 + LangGraph          │   │
│  │  nginx (prod)    │   SSE    │  Port 8000                       │   │
│  │  Port 80         │◄─────────┤                                  │   │
│  └─────────────────┘          └────────────┬─────────────────────┘   │
│                                            │ asyncpg                  │
│                                ┌───────────▼──────────────────────┐  │
│                                │  PostgreSQL 16                   │  │
│                                │  users · sessions · messages     │  │
│                                └──────────────────────────────────┘  │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  RAG Ingestion Pipeline  (offline / manual)                     │  │
│  │  Kaggle dataset → OpenAI embeddings → Qdrant Cloud upsert       │  │
│  └────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Component diagram (L3) — FastAPI Backend

```
FastAPI Backend
├── Auth Router          POST /auth/register, /login, /refresh, /logout
│   └── JWT Middleware   validates Bearer tokens · issues HS256 JWT pairs
├── Chat Router          POST /chat (SSE) · GET sessions/history · DELETE session
│   ├── Session Store    asyncpg pool → PostgreSQL
│   └── LangGraph Chain
│       ├── RAG Search Node      → RAG Service → Qdrant + OpenAI (embed)
│       ├── IMDb Enrichment Node → IMDb API Client → imdbapi.dev (async parallel)
│       ├── Validation Node      (dedup, confidence filter ≥ threshold)
│       ├── Presentation Node    (rank, format candidates for user)
│       ├── Confirmation Node    → Claude Haiku (classify intent)
│       ├── Refinement Node      → Claude Sonnet (extract plot details, max 3×)
│       ├── Q&A Agent Node       → Claude Sonnet + ReAct + IMDb tools
│       └── Dead-End Node        (graceful exit after 3 refinement cycles)
└── Health               GET /health → {"status": "ok"}
```

---

## LangGraph pipeline — phase state machine

```
[Entry]
   │
[RAG Search] ── embed query → Qdrant top-K
   │
[IMDb Enrichment] ── async parallel metadata fetch per candidate
   │
[Validation] ── dedup · filter by confidence
   ├── candidates found ──► [Presentation] ──► stream to user ──► [Confirmation]
   │                                                                    │
   │                                                          ┌─────────┴──────────┐
   │                                                     confirmed           refine / exhausted
   │                                                          │                    │
   │                                                     [Q&A Agent]        [Refinement] ──► loop ≤ 3×
   │                                                                               │
   └── no candidates ──────────────────────────────────────► [Dead-End]
```

---

## Deployment — Azure (production)

```
GitHub ──webhook──► Jenkins (Ubuntu + ngrok)
                          │ docker push
                    ┌─────▼─────────────────────────┐
                    │  Azure Container Registry      │
                    │  :sha8 · :latest · :v1.2.3     │
                    └─────┬─────────────────────────┘
                          │ az containerapp update
         ┌────────────────▼───────────────────────────────────────┐
         │         Azure Container Apps Environment                │
         │                                                         │
         │  movie-finder-frontend      ca-movie-finder             │
         │  nginx + Angular SPA        FastAPI + LangGraph         │
         │  min=1 max=5 replicas       min=1 max=4 replicas        │
         │                    │                                    │
         │                    └──► Azure PostgreSQL Flexible Server│
         └────────────────────────────────────────────────────────┘
              │                   │                    │
         Azure Key Vault     Qdrant Cloud        imdbapi.dev
         (secrets via        (external —         (unauthenticated)
          managed identity)   no container)
```

---

## Open architectural issues

The most impactful known issues affecting this architecture:

| #                                                      | Issue                                                                 | Severity     |
| ------------------------------------------------------ | --------------------------------------------------------------------- | ------------ |
| [#2](https://github.com/aharbii/movie-finder/issues/2) | `MemorySaver` non-persistent — breaks multi-replica deployments       | **Critical** |
| [#3](https://github.com/aharbii/movie-finder/issues/3) | Schema managed by raw DDL — no Alembic migrations, no indexes         | **Critical** |
| [#4](https://github.com/aharbii/movie-finder/issues/4) | No rate limiting on any API endpoint                                  | **High**     |
| [#5](https://github.com/aharbii/movie-finder/issues/5) | Refresh tokens cannot be revoked                                      | **High**     |
| [#7](https://github.com/aharbii/movie-finder/issues/7) | OpenAI + Qdrant clients re-created on every LangGraph node invocation | **High**     |
| [#8](https://github.com/aharbii/movie-finder/issues/8) | IMDb retry base delay 30 s — blocks SSE stream                        | **High**     |

See the [PlantUML diagrams](plantuml/index.md) for a full annotated view of all issues in context.
