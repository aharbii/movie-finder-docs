---
title: "ADR-001: Initial Architecture — Tech Stack and Repository Structure"
description: Rationale for the core technology choices and multi-repo submodule structure
---

# ADR-001: Initial Architecture — Tech Stack and Repository Structure

**Date:** 2025-Q4
**Status:** Accepted

---

## Context

Movie Finder needed a fullstack AI application capable of:
- Natural language movie search (semantic, not keyword)
- Live metadata enrichment from IMDb
- Real-time streamed conversation (SSE)
- Stateful multi-turn sessions with JWT authentication
- Independent team ownership of each subsystem
- Cloud deployment with secrets management

---

## Decisions

### 1. Multi-repo submodule structure

**Decision:** Each subsystem (backend app, LangGraph chain, IMDb client, RAG ingestion, frontend) is a separate Git repository, integrated via Git submodules in an orchestrator root.

**Rationale:**
- Each team can own, release, and deploy their subsystem independently
- Submodule pointers give the integration root explicit version control over each dependency
- Independent CI pipelines per repo (CONTRIBUTION / INTEGRATION / RELEASE modes)

**Consequence:** Submodule workflow is more complex than a flat monorepo. Contributors must understand submodule pointer commits. Mitigated by documentation (ONBOARDING.md, CONTRIBUTING.md).

---

### 2. FastAPI + Python 3.13

**Decision:** Python 3.13 with FastAPI for the backend API layer.

**Rationale:**
- LangGraph and LangChain have first-class Python support; no bridging layer required
- FastAPI's `async def` + `StreamingResponse` maps directly to SSE streaming
- Pydantic models serve as both validation and documentation (OpenAPI auto-generated)
- asyncpg provides high-performance async PostgreSQL access

---

### 3. LangGraph multi-agent pipeline

**Decision:** Compile the AI pipeline as a LangGraph `Pregel` graph with named nodes.

**Rationale:**
- State machine is explicit and auditable — no implicit chain-of-thought looping
- Refinement cycles are bounded (max 3) — prevents infinite loops
- Each node is independently testable
- LangGraph supports streaming events per node, enabling real-time SSE output

---

### 4. Qdrant Cloud for vector search

**Decision:** Use Qdrant Cloud (managed) as the vector store. No local Qdrant container in any environment.

**Rationale:**
- Managed service eliminates operational overhead (backups, scaling, upgrades)
- Single production cluster shared across all environments keeps embeddings consistent
- `text-embedding-3-large` (OpenAI, 3072 dim) chosen for quality; Qdrant's cosine similarity performs well at this dimension

**Consequence:** All environments (dev, staging, prod) share the same Qdrant cluster. A bad ingestion run affects all environments simultaneously. Mitigated by treating Qdrant as read-only outside the RAG ingestion pipeline.

---

### 5. PostgreSQL over SQLite

**Decision:** PostgreSQL 16 for the relational store (users, sessions, messages). SQLite was used during early development and migrated via `scripts/migrate_sqlite_to_postgres.py`.

**Rationale:**
- PostgreSQL Flexible Server on Azure supports horizontal scaling (multiple Container App replicas can share a single DB)
- SQLite does not support concurrent writes from multiple application replicas
- asyncpg provides connection pooling required for high-concurrency FastAPI workloads

---

### 6. JWT authentication (stateless)

**Decision:** Stateless JWT tokens (HS256). Access token: 30 minutes. Refresh token: 7 days.

**Rationale:**
- Stateless — no server-side session table required (sessions table stores *chat* sessions, not auth sessions)
- Short access token TTL limits exposure window if a token is intercepted
- Refresh token enables seamless UX without frequent re-login

---

### 7. Angular 21 SPA

**Decision:** Angular 21 with TypeScript 5.9 for the frontend.

**Rationale:**
- Strong typing prevents runtime errors in the SSE streaming parsing logic
- Angular's dependency injection and service layer cleanly separates API logic from UI
- Vitest provides fast unit tests with Angular TestBed compatibility

**Consequence:** Angular has a steeper learning curve than React for new contributors. Mitigated by `frontend/CONTRIBUTING.md` documenting Angular conventions used in this project.

---

### 8. Azure Container Apps

**Decision:** Azure Container Apps (ACA) for hosting, with Azure Database for PostgreSQL Flexible Server and Azure Container Registry.

**Rationale:**
- ACA is serverless — no VMs or Kubernetes clusters to manage
- Integrated managed identity for Key Vault secrets eliminates credential injection in pipelines
- Flexible Server supports `maxReplicas > 1` for the backend (unlike the original SQLite constraint)

---

### 9. Jenkins CI/CD over GitHub Actions

**Decision:** Self-hosted Jenkins (Ubuntu + ngrok) rather than GitHub Actions.

**Rationale:**
- Existing team familiarity with Jenkins
- Docker socket access on the build agent enables BuildKit cache mounts without cloud runner fees
- Jenkins credentials store is pre-existing infrastructure

**Consequence:** Jenkins requires on-premise maintenance (OS updates, plugin updates, ngrok URL rotation on free plan). GitHub Actions would reduce operational overhead and is the recommended path for future migration.

---

## Consequences — overall

**Positive:**
- Each team has clear ownership and release cadence
- The LangGraph graph is auditable — every node and edge is visible in code
- Azure managed services reduce operational burden (no DB or registry maintenance)

**Negative:**
- Multi-repo submodule workflow is complex for new contributors
- Shared Qdrant cluster means no environment isolation for vector data
- Jenkins requires active maintenance; a paid ngrok plan is recommended for production use

---

## Future considerations

- Migrate CI from Jenkins to GitHub Actions to reduce infrastructure overhead
- Add a Qdrant staging collection to isolate dev/staging from production vector data
- Consider Terraform/Bicep in `infrastructure/` to replace the `provision.sh` bash script
