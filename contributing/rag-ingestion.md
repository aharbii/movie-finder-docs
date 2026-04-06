---
title: RAG Ingestion Contributing Guide
description: Contributing to the RAG ingestion pipeline (movie-finder-rag)
---

# Contributing to the RAG Ingestion Pipeline

This guide covers working on `backend/rag_ingestion/` — the offline pipeline that builds the Qdrant vector collection.
Repo: `aharbii/movie-finder-rag`

For cross-cutting conventions see the [Contributing Overview](index.md).

---

## What this pipeline does

1. Downloads the Kaggle movie dataset via `kagglehub`
2. Generates `text-embedding-3-large` embeddings (3072 dimensions) for each movie's plot
3. Upserts the vectors into the `movies` collection in Qdrant Cloud

This is an **offline, manually triggered** pipeline — it is not part of the application request path.
Run it once to populate Qdrant, then only again when the dataset or embedding model changes.

---

## Development setup

`rag_ingestion/` is a standalone uv project (not a uv workspace member). From `backend/rag_ingestion/`:

```bash
make dev         # build + start dev container
make test        # run pytest inside Docker
make lint        # ruff check + format check
make typecheck   # mypy --strict
make pre-commit  # all hooks
```

To run the full ingestion (requires a Qdrant write key):

```bash
make ingest
```

---

## Embedding model coordination

**Critical:** The embedding model used at ingestion time must match the model used at query time.

| Setting               | Ingestion (`rag_ingestion/`) | Query time (`chain/`)      |
| --------------------- | ---------------------------- | -------------------------- |
| `EMBEDDING_MODEL`     | `text-embedding-3-large`     | `text-embedding-3-large`   |
| `EMBEDDING_DIMENSION` | `3072`                       | `3072`                     |

If you change the embedding model, update both repos and re-run the full ingestion to rebuild the collection. The existing vectors become incompatible with queries using a different model.

---

## Design patterns

- **Strategy pattern** — the embedding provider is an injectable strategy; no `if provider == "openai"` branching in core pipeline logic
- **Configuration object** — all settings via `config.py` (`Pydantic BaseSettings`); never `os.getenv()` scattered through business logic

---

## Running ingestion via Jenkins

The Jenkins pipeline supports a manual ingest trigger:

1. Jenkins → `movie-finder-rag` → `main` → **Build with Parameters**
2. Set `RUN_INGESTION=true`
3. Set `COLLECTION_NAME=movies` (or a test collection name to avoid overwriting production data)

Required Jenkins credentials: `qdrant-url`, `qdrant-api-key-rw`, `openai-api-key`, `kaggle-api-token`.

---

## Environment variables

Copy `.env.example` to `.env` and fill in:

```
OPENAI_API_KEY
QDRANT_URL, QDRANT_API_KEY_RW, QDRANT_COLLECTION_NAME
KAGGLE_API_TOKEN
EMBEDDING_MODEL=text-embedding-3-large
EMBEDDING_DIMENSION=3072
```

---

## Code standards

- `mypy --strict` must pass
- No raw `os.getenv()` — use `config.py`
- No `print()` — use `logging`
- Line length: 100
