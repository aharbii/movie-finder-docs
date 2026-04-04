# Movie Finder — PlantUML Architecture Diagrams

Generated with **PlantUML 1.2026.2** + **Graphviz 14.1.4**.

## Diagrams

| #   | File                                                               | Type       | Description                                                                                   |
| --- | ------------------------------------------------------------------ | ---------- | --------------------------------------------------------------------------------------------- |
| 01  | [01-domain-model.puml](01-domain-model.puml)                       | Class      | Domain entities: User, ChatSession, Message, MovieCandidate, ConfirmedMovie, MovieFinderState |
| 02  | [02-system-architecture.puml](02-system-architecture.puml)         | Component  | Full system overview: all components, external services, CI/CD                                |
| 03  | [03-backend-architecture.puml](03-backend-architecture.puml)       | Class      | FastAPI internal structure: routers, middleware, session store, config                        |
| 04  | [04-langgraph-pipeline.puml](04-langgraph-pipeline.puml)           | Class      | LangGraph 8-node pipeline: all nodes, services, state                                         |
| 05  | [05-langgraph-statemachine.puml](05-langgraph-statemachine.puml)   | State      | Phase lifecycle: discovery → confirmation → qa, refinement cycles                             |
| 06  | [06-frontend-architecture.puml](06-frontend-architecture.puml)     | Class      | Angular 21 SPA: services, guards, interceptors, components                                    |
| 07  | [07-seq-authentication.puml](07-seq-authentication.puml)           | Sequence   | Auth flow: register, login, token refresh, logout                                             |
| 08  | [08-seq-chat-sse.puml](08-seq-chat-sse.puml)                       | Sequence   | Chat & SSE streaming: full request lifecycle                                                  |
| 09  | [09-seq-langgraph-execution.puml](09-seq-langgraph-execution.puml) | Sequence   | LangGraph execution: all phases, refinement cycles, Q&A                                       |
| 10  | [10-deployment-azure.puml](10-deployment-azure.puml)               | Deployment | Azure production topology + local docker compose                                              |

## Rendering

```bash
# Single diagram
plantuml -png 01-domain-model.puml

# All diagrams at once
plantuml -png *.puml

# SVG (vector, better for docs)
plantuml -svg *.puml
```

## VS Code Preview

Open any `.puml` file → press `Alt+D` (or `Option+D` on macOS) to open the live preview panel.
The **jebbs.plantuml** extension v2.18.1 is configured in `.vscode/settings.json`.

## StarUML Conversion

Each `.puml` file maps to one StarUML diagram. When converting manually:

- **Class diagrams** → UMLClassDiagram
- **Component diagrams** → UMLComponentDiagram
- **Sequence diagrams** → UMLSequenceDiagram (UMLCollaboration → UMLInteraction)
- **State diagrams** → UMLStatechartDiagram
- **Deployment diagrams** → UMLDeploymentDiagram

## Known Issues Annotated

The diagrams include inline `⚠ Issue #N` annotations corresponding to the
tracked GitHub issues. These mark architectural debt for prioritisation.

| Issue                          | Severity | Location in diagrams |
| ------------------------------ | -------- | -------------------- |
| #2 MemorySaver non-persistent  | Critical | 04, 09, 10           |
| #3 No Alembic migrations       | Critical | 03, 10               |
| #4 No rate limiting            | High     | 02, 03, 08           |
| #5 Refresh token not revocable | High     | 01, 07               |
| #6 sys.exit in library         | High     | —                    |
| #7 Clients recreated per node  | High     | 04, 09               |
| #8 IMDb retry 30s delay        | High     | 04, 09               |
| #9 No CORS middleware          | Medium   | 02, 03, 08, 10       |
| #10 confirmed_movie as TEXT    | Medium   | 01, 03, 10           |
| #11 No pagination              | Medium   | 03                   |
| #12 UserInDB exposes hash      | Medium   | 03, 07               |
| #13 No input validation        | Medium   | 03, 08               |
| #14 Shared Qdrant cluster      | Medium   | 02, 10               |
| #15 total=False TypedDict      | Low      | 01, 04               |
| #16 IMDb stagger delay         | Low      | 04, 09               |
| #17 ngrok for webhooks         | Low      | 02, 10               |
