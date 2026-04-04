---
title: PlantUML Architecture Diagrams
description: UML architecture diagrams for Movie Finder — class, component, sequence, state, and deployment views
---

# Architecture Diagrams

10 PlantUML diagrams covering the full Movie Finder architecture.
Source files (`*.puml`) are in [`docs/architecture/plantuml/`](https://github.com/aharbii/movie-finder-docs/tree/main/architecture/plantuml).

!!! tip "Rendering locally"
    Run the full documentation build from the repo root — no local PlantUML install required:
    ```bash
    # Full docs build: prepares content, renders PlantUML PNGs, serves MkDocs
    make mkdocs
    # → http://localhost:8001
    ```
    Or start only the PlantUML server for VS Code live preview:
    ```bash
    make plantuml
    # → http://localhost:18088
    ```

!!! note "VS Code preview"
Open any `.puml` file and press `Option+D` (macOS) / `Alt+D` (Windows/Linux) for a live preview panel.
The **jebbs.plantuml** extension is pre-configured in `.vscode/settings.json`.

---

## 01 — Domain Model

Core data structures: identity, sessions, messaging, and AI pipeline state.

![Domain Model](01-domain-model.png)

---

## 02 — System Architecture Overview

All runtime components, external services, and CI/CD pipeline in one view.

![System Architecture](02-system-architecture.png)

---

## 03 — Backend Internal Architecture

FastAPI layer decomposition: routers, JWT middleware, session store, and configuration.

![Backend Architecture](03-backend-architecture.png)

---

## 04 — LangGraph Pipeline (Class View)

The `chain` module: all 8 LangGraph nodes, their services, and the shared `MovieFinderState`.

![LangGraph Pipeline](04-langgraph-pipeline.png)

---

## 05 — LangGraph Phase State Machine

Phase lifecycle (`discovery → confirmation → qa`), `next_action` routing signals, and refinement cycles.

![LangGraph State Machine](05-langgraph-statemachine.png)

---

## 06 — Frontend Architecture (Angular 21)

Component tree, core services, guards, interceptors, and feature modules.

![Frontend Architecture](06-frontend-architecture.png)

---

## 07 — Authentication Flow (Sequence)

Register, login, token refresh, and logout end-to-end.

![Authentication Sequence](07-seq-authentication.png)

---

## 08 — Chat & SSE Streaming Flow (Sequence)

Full lifecycle from `EventSource` fetch through JWT validation, session persistence, LangGraph streaming, and SSE event handling.

![Chat SSE Sequence](08-seq-chat-sse.png)

---

## 09 — LangGraph Pipeline Execution (Sequence)

All 8 nodes firing in sequence with conditional branching: discovery, confirmation, Q&A phase, and refinement cycles.

![LangGraph Execution Sequence](09-seq-langgraph-execution.png)

---

## 10 — Azure Production Deployment

Container Apps environment, PostgreSQL Flexible Server, ACR, Key Vault, Qdrant Cloud, Jenkins CI/CD, and local docker compose reference.

![Azure Deployment](10-deployment-azure.png)

---

## Known Issues cross-reference

Diagrams include inline `⚠ Issue #N` annotations for the issues that are still open in the current architecture docs. Quick reference:

| GitHub Issue                                                                       | Severity | Diagrams       |
| ---------------------------------------------------------------------------------- | -------- | -------------- |
| [#7 Clients recreated per node](https://github.com/aharbii/movie-finder/issues/7)  | High     | 04, 09         |
| [#8 IMDb retry 30 s delay](https://github.com/aharbii/movie-finder/issues/8)       | High     | 04, 09         |
| [#12 UserInDB exposes hash](https://github.com/aharbii/movie-finder/issues/12)     | Medium   | 03, 07         |
| [#14 Shared Qdrant cluster](https://github.com/aharbii/movie-finder/issues/14)     | Medium   | 02, 10         |
| [#15 total=False TypedDict](https://github.com/aharbii/movie-finder/issues/15)     | Low      | 01, 04         |
| [#17 ngrok for webhooks](https://github.com/aharbii/movie-finder/issues/17)        | Low      | 02, 10         |
