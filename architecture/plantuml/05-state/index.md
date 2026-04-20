---
title: State Diagrams
description: State machine diagrams for Movie Finder — LangGraph pipeline phases, session lifecycle, and JWT/refresh token lifecycle.
---

# State Diagrams

State machines for the key stateful components. Diagrams reflect the **target implementation**: persistent checkpointer (ADR-0007), JSONB confirmed_movie, paginated sessions, and full refresh token revocation.

---

## 01 — LangGraph Pipeline Phase State Machine

Phase lifecycle (`DISCOVERY → CONFIRMATION → Q&A`), `next_action` routing signals, refinement cycles, and PostgresSaver persistence between each node transition (ADR-0007).

![LangGraph Phase State Machine](01-st-langgraph-phases.png)

---

## 02 — Session Lifecycle

Session states from creation through discovery, confirmation (JSONB `confirmed_movie`), and Q&A to end state. Maps to the PostgreSQL `sessions.phase` column. Includes paginated history access.

![Session Lifecycle](02-st-session-lifecycle.png)

---

## 03 — JWT & Refresh Token Lifecycle

Parallel state machines for access tokens (30 min TTL, JWT) and refresh tokens (7 day TTL, opaque hash). Shows full revocation: `revoked=TRUE` set in DB on logout, validated on every refresh attempt.

![Token Lifecycle](03-st-token-lifecycle.png)
