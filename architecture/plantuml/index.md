---
title: UML Architecture Diagrams
description: Enterprise-level UML modeling for Movie Finder — 8 diagram categories covering use cases, domain, class, activity, state, component, sequence, and database design.
---

# UML Architecture Diagrams

Enterprise-level UML modeling for the Movie Finder system. Diagrams model the **target architecture** — each open issue is represented by its solution contract, not its current broken state. Source files (`.puml`) are version-controlled in [`docs/architecture/plantuml/`](https://github.com/aharbii/movie-finder-docs/tree/main/architecture/plantuml). PNGs are generated at build time.

!!! tip "Rendering locally"
    ```bash
    make mkdocs   # full build → http://localhost:8001
    make plantuml # VS Code preview server → http://localhost:18088
    ```
    Open any `.puml` file in VS Code and press `Option+D` / `Alt+D` with the **jebbs.plantuml** extension.

---

## Diagram Categories

| Category | Diagrams | Purpose |
|---|---|---|
| [00 — Context & Deployment](00-context/index.md) | System context, Azure deployment | System boundary and runtime topology |
| [01 — Use Cases](01-use-cases/index.md) | 5 use case diagrams | Actor/role capabilities mapped to target solutions |
| [02 — Domain Model](02-domain/index.md) | Domain entity model | Core entities and relationships |
| [03 — Class Diagrams](03-class/index.md) | 5 class diagrams | OOP structure: interfaces, design patterns, all providers |
| [04 — Activity Diagrams](04-activity/index.md) | 4 activity diagrams | Process flows: search, auth, RAG ingestion, Q&A |
| [05 — State Diagrams](05-state/index.md) | 3 state machines | LangGraph phases, session lifecycle, token lifecycle |
| [06 — Component Diagrams](06-component/index.md) | 4 component diagrams | Module structure and inter-service communication |
| [07 — Sequence Diagrams](07-sequence/index.md) | 4 sequence diagrams | Auth flow, chat SSE, pipeline execution, RAG ingestion |
| [08 — Database Design](08-database/index.md) | PostgreSQL ER diagram | Full schema with indexes, JSONB types, migration tracking |

---

## Open Issues — Architecture Contracts

Each open issue is modeled as a solution in the relevant diagrams. These serve as implementation contracts.

| Issue | Diagrams modeling the solution |
|---|---|
| [#14 Shared Qdrant cluster](https://github.com/aharbii/movie-finder/issues/14) | Component (inter-service), Class (RAG), Activity (RAG), Sequence (RAG), Use Cases (RAG) |
| [#17 Jenkins ngrok webhooks](https://github.com/aharbii/movie-finder/issues/17) | Component (inter-service), Context |
| [#21 Migrate CI to GitHub Actions](https://github.com/aharbii/movie-finder/issues/21) | Component (inter-service), Activity (RAG), Sequence (RAG) |
| [#22 Infrastructure as Code (Terraform/Bicep)](https://github.com/aharbii/movie-finder/issues/22) | Component (inter-service), Context (deployment) |
| [#29 Parameterized CI ingestion job + metrics](https://github.com/aharbii/movie-finder/issues/29) | Use Cases (RAG), Activity (RAG), Sequence (RAG), Class (RAG) |
| [#31 Chunking strategy framework](https://github.com/aharbii/movie-finder/issues/31) | Class (RAG), Activity (RAG), Sequence (RAG), Design patterns |
| [#33 Expand provider support](https://github.com/aharbii/movie-finder/issues/33) | Class (RAG), Design patterns, Component (chain, inter-service) |
| [#42 LLM & Embedding Provider Factory (ADR-0008)](https://github.com/aharbii/movie-finder/issues/42) | Class (design patterns, RAG, chain), Component (chain, inter-service), Activity (RAG) |
