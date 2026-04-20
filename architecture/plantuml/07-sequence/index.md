---
title: Sequence Diagrams
description: Interaction sequence diagrams for Movie Finder — authentication, chat SSE streaming, LangGraph pipeline execution, and RAG ingestion (target architecture).
---

# Sequence Diagrams

Message-order sequences between participants for each major interaction. Diagrams reflect the **target implementation**.

---

## 01 — Authentication Flow

Register, login (rate-limited), JWT signing, refresh token storage, Angular interceptor 401 handling, token refresh, and logout with DB revocation.

![Authentication Sequence](01-seq-authentication.png)

---

## 02 — Chat & SSE Streaming Flow

`EventSource` fetch → JWT validation → session load → LangGraph streaming → token-by-token SSE → DB persistence. Shows the persistent checkpointer state load and LLMProvider singleton invocation.

![Chat SSE Sequence](02-seq-chat-sse.png)

---

## 03 — LangGraph Pipeline Execution

All 8 nodes in sequence with conditional edges, external API calls, state checkpointing after each node, and final SSE event emission.

![LangGraph Execution Sequence](03-seq-langgraph-execution.png)

---

## 04 — RAG Ingestion Pipeline (Target Architecture — Issues #14, #21, #29, #31, #33, #42)

GitHub Actions parameterized trigger → factory setup (ADR-0008) → environment-scoped collection (Issue #14) → pluggable chunking (Issue #31) → **batch** embedding per provider → vector store upsert → `IngestionMetrics` exported as step summary + JSON artifact (Issue #29).

![RAG Ingestion Sequence](04-seq-rag-ingestion.png)
