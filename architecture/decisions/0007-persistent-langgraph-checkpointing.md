---
title: "0007: Persistent LangGraph Checkpointing Owned by the Backend Runtime"
description: Rationale for database-backed LangGraph checkpoints, backend lifecycle ownership, and the deployed DATABASE_URL contract
---

# ADR-003: Persistent LangGraph Checkpointing Owned by the Backend Runtime

**Date:** 2026-04-04
**Status:** Accepted

---

## Context

Movie Finder moved from process-local LangGraph conversation state to a deployment model that must
survive both process restarts and replica hops in Azure Container Apps.

The initial runtime shape allowed in-process checkpointing, which was acceptable for local
development but incorrect for deployed multi-replica environments:

- Conversation continuity was tied to a single backend process.
- Restarting a replica could discard active LangGraph state.
- Replica-to-replica routing could break an ongoing conversation even when the relational session
  rows still existed in PostgreSQL.
- `DATABASE_URL` was documented primarily as the backend session-store contract, even though the
  deployed runtime also needed shared conversation-state persistence.

At the same time, the chain and backend repos had already converged on a clearer separation of
responsibilities:

- The `chain` package exposes `checkpoint_lifespan(db_url: str | None = None)`.
- The graph supports `compile_graph(checkpointer=...)`.
- The backend runtime owns creation, storage, injection, and shutdown of the shared saver.

---

## Decision

### 1. Production conversation continuity uses shared persistent checkpoints

In deployed environments, LangGraph conversation state is persisted through a shared
`BaseCheckpointSaver` backed by PostgreSQL. Memory-only checkpointing is treated as an explicit
local or test fallback only.

### 2. The backend owns the checkpointer lifecycle

The FastAPI application is the runtime boundary that creates and tears down the checkpointer:

1. Resolve `DATABASE_URL` from the deployed environment.
2. Enter `checkpoint_lifespan(DATABASE_URL)` during FastAPI lifespan startup.
3. Store the shared saver on `app.state`.
4. Compile the singleton graph with `compile_graph(checkpointer=...)`.
5. Reuse that graph across requests.
6. Close the saver cleanly during shutdown.

The chain package does not own production persistence wiring. It provides the lifecycle and
injection hooks, while the backend owns runtime composition.

### 3. `DATABASE_URL` is a shared runtime contract

`DATABASE_URL` is not only the backend session-store connection string. In deployed environments it
is also part of the LangGraph checkpoint persistence contract.

PostgreSQL now serves two distinct persistence concerns:

- Backend application data: users, sessions, messages, refresh-token revocation state.
- LangGraph checkpoints: conversation state used to resume graph execution across requests,
  restarts, and replica changes.

Qdrant remains separate and is used only for vector retrieval.

---

## Consequences

**Positive:**

- Conversation continuity survives backend process restarts.
- Multi-replica deployments can preserve state across replica hops.
- Runtime ownership is explicit: backend composes and owns the persistent checkpointer.
- Docs, deployment assumptions, and environment contracts can describe one production model instead
  of mixing process-local and shared-state language.

**Negative:**

- PostgreSQL availability now affects both session storage and LangGraph checkpoint continuity.
- Deployment docs must treat `DATABASE_URL` as a broader runtime dependency than before.
- Local and test docs must be careful to distinguish explicit memory-only fallback behavior from
  the deployed production model.

---

## Alternatives considered

- **Continue using process-local `MemorySaver` in production** — rejected because it breaks restart
  durability and replica-to-replica continuity.
- **Move checkpointer ownership into the chain package** — rejected because runtime wiring belongs
  at the backend boundary, where FastAPI lifespan and app state are already owned.
- **Introduce a separate persistence service for checkpoints** — rejected as unnecessary because the
  implemented contract already uses PostgreSQL and does not introduce another runtime service.
