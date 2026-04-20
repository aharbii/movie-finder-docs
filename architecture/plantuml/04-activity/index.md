---
title: Activity Diagrams
description: Process flow diagrams for Movie Finder — movie search, authentication, RAG ingestion (target), and chat Q&A.
---

# Activity Diagrams

End-to-end process flows with decision points, parallel forks, and swimlane ownership. Diagrams model the **target architecture** — flows reflect implemented features and the solution contracts for open issues.

---

## 01 — Movie Search Flow (End-to-End)

From natural-language input through JWT validation, EmbeddingProvider singleton lookup, environment-scoped Qdrant search, parallel IMDb enrichment, Claude Sonnet candidate generation, and SSE streaming back to the browser. Includes refinement loop and JSONB-stored confirmation handoff.

![Movie Search Activity](01-act-movie-search.png)

---

## 02 — Authentication Flow

Four sub-flows: register (bcrypt hash, UserPublic response), login (rate-limited, JWT + refresh token issued), token refresh (Angular interceptor + revoked-flag check), and logout (refresh token marked `revoked=TRUE` in DB).

![Authentication Activity](02-act-authentication.png)

---

## 03 — RAG Ingestion Pipeline (Target Architecture — Issues #14, #21, #29, #31, #33, #42)

GitHub Actions parameterized job trigger → factory instantiation (ADR-0008) → dataset load → pluggable chunking strategy (Issue #31) → batch embedding (provider-agnostic) → environment-scoped collection upsert (Issue #14) → `IngestionMetrics` exported as GHA step summary and JSON artifact (Issue #29).

![RAG Ingestion Activity](03-act-rag-ingestion.png)

---

## 04 — Chat Q&A Flow (Post-Confirmation)

Authenticated follow-up questions: JWT validation → paginated session load → persistent LangGraph checkpointer state → `LLMProvider.generate()` via factory singleton → SSE token streaming → DB persistence.

![Chat Q&A Activity](04-act-chat-qa.png)
