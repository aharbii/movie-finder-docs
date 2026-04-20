---
title: Component Diagrams
description: Component-level architecture for Movie Finder — backend, chain nodes (target: singleton providers), frontend, and inter-service communication map (target: GitHub Actions, IaC).
---

# Component Diagrams

Module boundaries, provided/required interfaces, and internal wiring. The inter-service diagram models the **target CI/CD and provider topology**.

---

## 01 — Backend Application (FastAPI)

FastAPI layer: routers, JWT middleware, rate-limiting, CORS, asyncpg pool, repository layer, service layer, and `Depends()` injection chain.

![Backend Component Diagram](01-cmp-backend.png)

---

## 02 — LangGraph Chain Nodes (Target: ADR-0007 + ADR-0008)

All 8 nodes with singleton service dependencies injected via `Depends()` at startup (ADR-0008 — no per-call re-creation), `PostgresSaver` persistent checkpointer (ADR-0007), environment-scoped Qdrant collection (Issue #14), and full external provider connectivity.

![Chain Nodes Component Diagram](02-cmp-chain-nodes.png)

---

## 03 — Frontend Architecture (Angular 21)

Component tree, core services, route guards, interceptors, and the smart/dumb component split with Signal-based reactive data flow.

![Frontend Component Diagram](03-cmp-frontend.png)

---

## 04 — Inter-Service Communication Map (Target Architecture)

All cross-repo communication protocols with target topology:

- CORS-enabled REST + SSE between Angular and FastAPI
- Provider-agnostic AI API connections (ADR-0008: Anthropic / OpenAI / Ollama)
- Environment-scoped vector store connections (Issue #14: Qdrant / Pinecone / Weaviate)
- GitHub Actions CI replacing Jenkins + ngrok (Issues #17, #21)
- Terraform / Bicep IaC managing Azure resources (Issue #22)
- RAG ingestion metrics exported to GHA step summary (Issue #29)

![Inter-Service Communication](04-cmp-inter-service.png)
