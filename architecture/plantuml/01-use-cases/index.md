---
title: Use Case Diagrams
description: Actor and role capabilities for Movie Finder — movie search, authentication, chat Q&A, RAG ingestion, and system roles. Each diagram models the target solution.
---

# Use Case Diagrams

Use case diagrams define the system boundary, identify all actors, and map capabilities to roles. Diagrams model the **target state** — open issues are shown as solved features.

---

## 01 — Movie Search

User-initiated semantic search through the full AI pipeline. Shows Claude Haiku (intent classification), environment-scoped Qdrant collection (Issue #14 solution), IMDb enrichment, and Claude Sonnet candidate generation.

![Movie Search Use Case](01-uc-movie-search.png)

---

## 02 — Authentication

Register, login (with rate limiting), token refresh, and logout with full refresh token revocation against the PostgreSQL blacklist.

![Authentication Use Case](02-uc-authentication.png)

---

## 03 — Chat & Q&A

Post-confirmation chat: send message, receive SSE-streamed response, paginated session history, and conversation continuation across sessions.

![Chat Q&A Use Case](03-uc-chat-qa.png)

---

## 04 — RAG Ingestion (Target Architecture)

Parameterized pipeline (Issue #29): runtime selection of embedding provider (Issue #33 / ADR-0008), vector store (Issue #33), chunking strategy (Issue #31), and environment-scoped collection (Issue #14). Metrics exported to GitHub Actions (Issue #21).

![RAG Ingestion Use Case](04-uc-rag-ingestion.png)

---

## 05 — System Roles Map

All actors (Guest, Authenticated User, Data Engineer, DevOps/Admin, GitHub Actions CI) and the full capability set each role exercises.

![System Roles Map](05-uc-system-roles.png)
