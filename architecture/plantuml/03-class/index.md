---
title: Class Diagrams
description: OOP structure, interfaces, and design pattern catalog for Movie Finder — backend app, chain pipeline, RAG ingestion (target providers), design patterns, and frontend.
---

# Class Diagrams

Detailed OOP structure for each major subsystem. Models the **target architecture**: all provider interfaces include planned implementations, all repositories reflect the correct schema, and the design pattern catalog shows the complete factory roster (ADR-0008).

---

## 01 — Backend Application Layer (FastAPI)

Pydantic models with validation constraints, repository classes with correct column types (JSONB, paginated sessions), service layer, FastAPI routers with full endpoint signatures, CORS middleware, rate limiting on all relevant routes, and dependency injection wiring.

![Backend App Classes](01-cls-backend-app.png)

---

## 02 — LangGraph Chain Pipeline

All 8 LangGraph nodes, `MovieFinderGraph` orchestrator, singleton service dependencies (ADR-0008), `PostgresSaver` persistent checkpointer (ADR-0007), and shared `MovieFinderState` with `total=True`.

![Chain Pipeline Classes](02-cls-chain-pipeline.png)

---

## 03 — RAG Ingestion Pipeline (Target Architecture)

Full provider roster per ADR-0008 and Issues #33, #42:

- **Embedding**: `OpenAIEmbeddingProvider`, `AnthropicEmbeddingProvider`, `OllamaEmbeddingProvider`, `SentenceTransformerEmbeddingProvider`
- **Vector store**: `QdrantVectorStore`, `PineconeVectorStore`, `WeaviateVectorStore` — all with `env_collection_name()` for Issue #14 isolation
- **Chunking** (Issue #31): `FixedSizeChunker`, `SemanticChunker`, `SentenceBasedChunker`
- **Factories**: `EmbeddingProviderFactory`, `VectorStoreFactory`, `ChunkingStrategyFactory`
- `IngestionMetrics` with `to_gha_summary()` for Issue #29

![RAG Ingestion Classes](03-cls-rag-ingestion.png)

---

## 04 — OOP & Design Pattern Catalog

Complete design pattern reference across all subsystems:

- **Strategy** (×4): Embedding providers, LLM providers, vector store providers, chunking strategies
- **Factory** (×4): `LLMProviderFactory`, `EmbeddingProviderFactory`, `VectorStoreFactory`, `ChunkingStrategyFactory`
- **Repository**: `BaseRepository` hierarchy (User, Session, Message, RefreshToken)
- **Adapter**: `IMDbApiClient` → `MovieMetadataSource`
- **Dependency Injection**: FastAPI `Depends()` chain for singleton providers
- **State Machine**: `MovieFinderState` TypedDict with `total=True`

![Design Pattern Catalog](04-cls-design-patterns.png)

---

## 05 — Angular 21 Frontend Components & Services

TypeScript domain interfaces, `AuthService` / `ChatService` facade layer with Signals, `AuthInterceptor`, `TokenRefreshInterceptor`, `AuthGuard` / `GuestGuard`, smart components (own services), and dumb components (`@Input()` only).

![Frontend Component Classes](05-cls-frontend-components.png)
