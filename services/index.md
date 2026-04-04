---
title: Services
description: Individual service documentation for Movie Finder
---

# Services

Movie Finder is composed of five independently versioned services. Each has its own repository, CI pipeline, and README.

---

## Service map

```
movie-finder (root orchestrator)
├── frontend/          Angular 21 SPA
└── backend/           FastAPI integration root
    ├── app/           Auth · Chat · Session Store
    ├── chain/         LangGraph multi-agent pipeline
    ├── imdbapi/       Async IMDb REST API client
    └── rag_ingestion/ Dataset → embed → Qdrant
```

---

## Services

| Service                           | Language                | Team                  | Status | README                                                                 |
| --------------------------------- | ----------------------- | --------------------- | ------ | ---------------------------------------------------------------------- |
| [Frontend](frontend.md)           | TypeScript / Angular 21 | Frontend              | Active | [frontend/README.md](https://github.com/aharbii/movie-finder-frontend) |
| [Backend App](backend.md)         | Python 3.13 / FastAPI   | App / Backend         | Active | [backend/README.md](https://github.com/aharbii/movie-finder-backend)   |
| [LangGraph Chain](chain.md)       | Python 3.13 / LangGraph | AI Engineering        | Active | [chain/README.md](https://github.com/aharbii/movie-finder-chain)       |
| [IMDb API Client](imdbapi.md)     | Python 3.13 / httpx     | IMDb API              | Active | [imdbapi/README.md](https://github.com/aharbii/imdbapi-client)         |
| [RAG Ingestion](rag-ingestion.md) | Python 3.13 / pandas    | AI / Data Engineering | Active | [rag_ingestion/README.md](https://github.com/aharbii/movie-finder-rag) |

---

## Dependency flow

```
movie-finder-rag ──[Qdrant endpoint+key]──► movie-finder-chain ◄──[pip]── imdbapi-client
                                                    │
                                                    │ pip (uv workspace)
                                                    ▼
                                        movie-finder-backend (FastAPI)
                                                    │
                                                    ▼
                                          Angular SPA (frontend)
                                                    │
                                                    ▼
                                               End users
```

---

!!! info "Content populated at build time"
The individual service pages (`frontend.md`, `backend.md`, etc.) are copied
from each submodule's `README.md` during the documentation build.
To populate them locally, run `make mkdocs` from the repo root.
