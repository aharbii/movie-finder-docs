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
| **StarUML**     | `architecture/architecture.mdj` | Stakeholder export format — never generated programmatically                     | Maintained manually by the project owner from the `.puml` and `.dsl` sources |

PlantUML and Structurizr are both committed as source. `architecture.mdj` is tracked in the repo for offline stakeholder reviews; it is updated manually — **never generate it programmatically**.

---

## How to view diagrams

=== "Full documentation site (recommended)"

    ```bash
    # from repo root — builds everything including PlantUML PNGs and serves MkDocs
    make mkdocs
    # → http://localhost:8001
    ```

    No local PlantUML install needed. The mkdocs container includes PlantUML and graphviz.

=== "PlantUML — VS Code live preview"

    1. Start the PlantUML server (no host install needed):
    ```bash
    # from repo root
    make plantuml
    # → http://localhost:18088
    ```

    2. Open any `.puml` file in VS Code and press `Alt+D` (macOS: `Option+D`).

    The **jebbs.plantuml** extension is pre-configured in `.vscode/settings.json` to use
    the local server at `http://localhost:18088`. The server must be running for preview to work.

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
│  │  Port 80         │◄─────────┤  owns shared checkpointer        │   │
│  └─────────────────┘          └────────────┬─────────────────────┘   │
│                                            │ asyncpg + checkpoints    │
│                                ┌───────────▼──────────────────────┐  │
│                                │  PostgreSQL 16                   │  │
│                                │  users · sessions · messages     │  │
│                                │  refresh_token_blocklist         │  │
│                                │  LangGraph checkpoints           │  │
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
│   ├── Session Store    asyncpg pool → PostgreSQL app tables + refresh-token blocklist
│   └── LangGraph Chain  singleton graph compiled with backend-owned shared checkpointer
│       ├── RAG Search Node      → RAG Service → Qdrant + OpenAI (embed)
│       ├── IMDb Enrichment Node → IMDb API Client → imdbapi.dev (async parallel)
│       ├── Validation Node      (dedup, confidence filter ≥ threshold)
│       ├── Presentation Node    (rank, format candidates for user)
│       ├── Confirmation Node    → Claude Haiku (classify intent)
│       ├── Refinement Node      → Claude Sonnet (extract plot details, max 3×)
│       ├── Q&A Agent Node       → Claude Sonnet + ReAct + IMDb tools
│       └── Dead-End Node        (graceful exit after 3 refinement cycles)
├── Lifespan Runtime     creates shared checkpointer from `DATABASE_URL` · stores it on `app.state`
│                        compiles singleton graph with `compile_graph(checkpointer=...)`
└── Health               GET /health/live · GET /health/ready

Production runtime uses two distinct PostgreSQL-backed persistence concerns:

- Backend session storage: users, chat sessions, chat messages, and refresh-token revocation state.
- LangGraph checkpoint persistence: conversation state owned by the backend runtime and shared across replicas through the injected checkpointer.

Qdrant remains a separate external vector store used only for semantic retrieval; it is not part of either PostgreSQL-backed persistence path.
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
         │                         sessions + blocklist +          │
         │                         LangGraph checkpoints           │
         └────────────────────────────────────────────────────────┘
              │                   │                    │
         Azure Key Vault     Qdrant Cloud        imdbapi.dev
         (secrets via        (external —         (unauthenticated)
          managed identity)   no container)
```

In deployed environments, the backend container entrypoint runs `alembic upgrade head` before `uvicorn` starts. During FastAPI lifespan startup, the backend creates one shared checkpointer from `DATABASE_URL`, stores it on `app.state`, compiles the singleton graph with that saver, and reuses it across requests. This is the runtime contract that preserves conversation continuity across process restarts and replica hops.

---

## Selected remaining architectural issues

The highest-signal architecture issues still called out in the current docs:

| #                                                        | Issue                                                                 | Severity   |
| -------------------------------------------------------- | --------------------------------------------------------------------- | ---------- |
| [#7](https://github.com/aharbii/movie-finder/issues/7)   | OpenAI + Qdrant clients re-created on every LangGraph node invocation | **High**   |
| [#8](https://github.com/aharbii/movie-finder/issues/8)   | IMDb retry base delay 30 s — blocks SSE stream                        | **High**   |
| [#12](https://github.com/aharbii/movie-finder/issues/12) | `UserInDB` still exposes `hashed_password` through auth dependencies  | **Medium** |
| [#14](https://github.com/aharbii/movie-finder/issues/14) | Shared Qdrant cluster across environments                             | **Medium** |
| [#17](https://github.com/aharbii/movie-finder/issues/17) | ngrok-based Jenkins webhook delivery                                  | **Low**    |

See the [PlantUML diagrams](plantuml/index.md) for the detailed runtime and deployment views.
