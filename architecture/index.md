---
title: Architecture
description: Movie Finder system architecture — C4 model, diagrams, and decisions
---

# Architecture

This section documents the Movie Finder architecture using [C4 model](https://c4model.com/) diagrams (Structurizr DSL) and UML class/sequence diagrams (StarUML).

---

## Files in this section

| File | Format | How to open |
|------|--------|-------------|
| [`workspace.dsl`](workspace.dsl) | Structurizr DSL | `docker compose --profile docs up structurizr` → [localhost:8080](http://localhost:8080) |
| [`architecture.mdj`](architecture.mdj) | StarUML JSON | StarUML desktop → File → Open |
| [`decisions/`](decisions/index.md) | Markdown ADRs | Read directly in GitHub or MkDocs |

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
                               Qdrant  Anthropic   OpenAI
                               Cloud   Claude API  Embeddings
                                    │
                               imdbapi.dev
                               (unauthenticated)
```

**External systems:**

| System | Purpose | Auth |
|--------|---------|------|
| Qdrant Cloud | Vector similarity search over movie corpus | API key |
| Anthropic Claude | LLM for chain (Haiku: classification, Sonnet: Q&A) | API key |
| OpenAI | `text-embedding-3-large` at query time and ingestion | API key |
| imdbapi.dev | Live IMDb metadata — ratings, posters, credits | None |
| Azure Key Vault | Runtime secrets injection via managed identity | Managed identity |

---

## Container diagram (L2)

```
┌────────────────────────────────────────────────────────────────────┐
│                       Movie Finder System                           │
│                                                                     │
│  ┌─────────────────┐         ┌──────────────────────────────────┐  │
│  │  Angular SPA     │  REST   │         FastAPI Backend           │  │
│  │  TypeScript 5.9  ├────────►│  Python 3.13 + LangGraph         │  │
│  │  nginx (prod)    │   SSE   │  Port 8000                       │  │
│  │  Port 80         │◄────────┤                                  │  │
│  └─────────────────┘         └──────────┬───────────────────────┘  │
│                                         │ asyncpg                   │
│                               ┌─────────▼──────────────────────┐  │
│                               │  PostgreSQL 16                  │  │
│                               │  Users / Sessions / Messages    │  │
│                               └────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  RAG Ingestion Pipeline (offline / manual)                    │  │
│  │  Kaggle dataset → OpenAI embeds → Qdrant Cloud upsert         │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Component diagram (L3) — FastAPI Backend

```
FastAPI Backend
├── Auth Router          POST /auth/register, /login, /refresh
│   └── JWT Middleware   validates Bearer tokens, returns user_id
├── Chat Router          POST /chat (SSE), GET sessions/history, DELETE session
│   ├── Session Store    asyncpg — users, sessions, messages → PostgreSQL
│   └── LangGraph Chain
│       ├── RAG Search Node    → RAG Service → Qdrant Cloud
│       │                                    → OpenAI (embed query)
│       ├── IMDb Enrichment    → IMDb API Client → imdbapi.dev
│       ├── Validation Node    (dedup, confidence filter)
│       ├── Presentation Node  (rank, format candidates)
│       ├── Confirmation Node  (await user pick)
│       ├── Q&A Agent Node     → Anthropic Claude Sonnet
│       ├── Refinement Node    (rebuild query, max 3 cycles)
│       └── Dead-End Node      (no matches after max cycles)
└── Health               GET /health  →  {"status": "ok"}
```

---

## LangGraph pipeline — state machine

```
        ┌──────────────────────────────────────────────────────────┐
        │                     Entry Point                           │
        └──────────────────────┬───────────────────────────────────┘
                               │
                        [RAG Search]
                     embed query → Qdrant top-K
                               │
                     [IMDb Enrichment]
                     fetch live metadata per candidate
                               │
                       [Validation]
                    dedup · filter (confidence < threshold)
                         /               \
            candidates found           no confident candidates
                  │                    OR user rejection
           [Presentation]                    │
          rank + format list           [Refinement] ◄── cycle 1, 2, 3
                  │                         │
          stream to user →         max cycles reached?
          wait for next turn              │  Yes
                  │                  [Dead-End]
           [Confirmation]
         user picks a movie
                  │
           [Q&A Agent]
        Claude Sonnet answers
        any follow-up question
        (no token streaming —
         full reply in done event)
```

---

## Deployment — Azure (production)

```
GitHub ──webhook──► Jenkins (Ubuntu + ngrok)
                          │
                    ┌─────▼───────────────────┐
                    │  Azure Container Registry │
                    │  :sha8  :latest  :v1.2.3  │
                    └─────┬───────────────────-┘
                          │  az containerapp update
              ┌───────────┼────────────────────────────────────┐
              │      Azure Container Apps Environment           │
              │                                                 │
              │  movie-finder-frontend  movie-finder-backend    │
              │  nginx + Angular SPA    FastAPI + LangGraph     │
              │  min=1 max=5            min=1 max=4             │
              │  Port 80                Port 8000               │
              │           │                                     │
              │           └──► Azure PostgreSQL Flexible Server │
              └─────────────────────────────────────────────────┘
              │
              ├── Azure Key Vault (secrets → backend via managed identity)
              └── Qdrant Cloud (external — no container)
```

---

## Rendering these diagrams

### Structurizr (C4 interactive)

```bash
# Start via docker compose (docs profile)
docker compose --profile docs up structurizr

# Open http://localhost:8080
# Navigate between: System Context · Containers · Components · Deployment
```

### StarUML (class + sequence diagrams)

```bash
# 1. Install StarUML: https://staruml.io
# 2. File → Open → docs/architecture/architecture.mdj
```

The StarUML model contains:
- **Domain Class Diagram** — User, ChatSession, Message, MovieCandidate, ConfirmedMovie, TokenPair
- **Sequence: Auth Flow** — register / login / refresh
- **Sequence: Chat SSE** — fetch → JWT validate → chain → SSE stream → persist
- **Sequence: LangGraph Chain** — full node execution with refinement cycles
