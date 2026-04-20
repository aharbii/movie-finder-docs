---
title: Movie Finder
description: AI-powered movie discovery and Q&A — project documentation home
---

# Movie Finder

AI-powered movie discovery and Q&A. Describe a film you half-remember and the system finds it, enriches it with live IMDb data, and answers follow-up questions in a streamed conversation.

---

## Quick navigation

<div class="grid cards" markdown>

-   **Getting Started**

    Zero-to-running guide for all roles — prerequisites, cloning, secrets, local stack.

    [:octicons-arrow-right-24: Onboarding guide](onboarding.md)

-   **API Reference**

    OpenAPI 3.1.0 specification with interactive Swagger UI.

    [:octicons-arrow-right-24: API docs](api/index.md)

-   **Architecture**

    C4 model, class diagrams, sequence diagrams, and architecture decision records.

    [:octicons-arrow-right-24: Architecture](architecture/index.md)

-   **DevOps & Platform**

    Jenkins setup, Azure provisioning, CI/CD pipeline guide, secrets management.

    [:octicons-arrow-right-24: DevOps setup](devops/setup.md)

-   **Services**

    Individual service documentation — backend, frontend, chain, IMDb client, RAG ingestion.

    [:octicons-arrow-right-24: Services](services/index.md)

-   **Contributing**

    Branching strategy, commit conventions, PR process, code standards, testing requirements.

    [:octicons-arrow-right-24: Contributing](contributing/index.md)

</div>

---

## System overview

```
Browser (Angular 21 SPA)
        │  REST + SSE  (JWT Bearer)
        ▼
FastAPI Backend  ─────────────────────────────────────────────────┐
        │                                                         │
        ▼                                                         ▼
LangGraph Chain                                           PostgreSQL
 ├── Shared checkpoints ◄── backend-owned checkpointer      users / sessions /
 ├── RAG Search ──► Qdrant Cloud (3072-dim vector store)    messages / checkpoints
 ├── IMDb Enrichment ──► imdbapi.dev                        / token blocklist
 ├── Validation
 ├── Presentation
 ├── Confirmation ◄── user picks a movie
 ├── Q&A Agent (Claude Sonnet — answers questions)
 └── Refinement (up to 3 re-query cycles)

LLMs:  Anthropic Claude (chain)  ·  OpenAI text-embedding-3-large
Cloud: Azure Container Apps  ·  Azure PostgreSQL Flexible Server  ·  ACR  ·  Key Vault
CI/CD: Jenkins (CONTRIBUTION → INTEGRATION → RELEASE)
```

---

## Repository map

| Submodule                                                                   | Description                          |
| --------------------------------------------------------------------------- | ------------------------------------ |
| [`backend/`](https://github.com/aharbii/movie-finder-backend)               | FastAPI + LangGraph integration root |
| [`backend/app/`](https://github.com/aharbii/movie-finder-backend)           | Auth, chat routers, session store    |
| [`backend/chain/`](https://github.com/aharbii/movie-finder-chain)           | LangGraph multi-agent pipeline       |
| [`backend/chain/imdbapi/`](https://github.com/aharbii/imdbapi-client)       | Async IMDb REST API client           |
| [`rag/`](https://github.com/aharbii/movie-finder-rag)     | Dataset → embed → Qdrant ingestion   |
| [`frontend/`](https://github.com/aharbii/movie-finder-frontend)             | Angular 21 SPA                       |
| [`docs/`](https://github.com/aharbii/movie-finder-docs)                     | This documentation site              |
| [`infrastructure/`](https://github.com/aharbii/movie-finder-infrastructure) | IaC and provisioning scripts         |

---

## Tech stack at a glance

| Layer            | Technology                                                    |
| ---------------- | ------------------------------------------------------------- |
| Frontend         | Angular 21, TypeScript 5.9, Vitest, ESLint 9, nginx           |
| Backend          | Python 3.13, FastAPI, LangGraph, asyncpg                      |
| AI — reasoning   | Anthropic Claude Haiku (classification) + Sonnet (Q&A)        |
| AI — embeddings  | OpenAI `text-embedding-3-large` (3072 dim)                    |
| Vector store     | Qdrant Cloud                                                  |
| Relational DB    | PostgreSQL 16                                                 |
| Containerisation | Docker multi-stage builds                                     |
| CI/CD            | Jenkins (Multibranch Pipelines)                               |
| Registry         | Azure Container Registry                                      |
| Cloud            | Azure Container Apps + PostgreSQL Flexible Server + Key Vault |

---

## License

This project is released under the [MIT License](https://github.com/aharbii/movie-finder/blob/main/LICENSE).
