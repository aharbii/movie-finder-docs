---
title: Chain Contributing Guide
description: Contributing to the LangGraph pipeline (movie-finder-chain)
---

# Contributing to the LangGraph Chain

This guide covers working on `backend/chain/` — the LangGraph 8-node AI pipeline.
Repo: `aharbii/movie-finder-chain`

For cross-cutting conventions (branching, commits, PRs, releases) see the [Contributing Overview](index.md).

---

## Pipeline overview

```
classify → search_rag → enrich_imdb → reason → route
                                                  │
                    ┌─────────────────────────────┤
                    │                             │
                 refine (≤3×)               confirm → qa_agent
                    │                             │
                  dead_end ◄────────────────── (exhausted)
```

All state is carried in `MovieFinderState` (TypedDict, `src/chain/state.py`).
Nodes are pure functions: they receive the full state and return a partial update.

---

## Development setup

The chain runs inside the backend Docker stack. From `backend/chain/`:

```bash
make dev         # build + start chain container with volume mount
make shell       # attach a shell to the running container
make test        # run pytest inside Docker
make lint        # ruff check + format check
make typecheck   # mypy --strict
make pre-commit  # all hooks
```

You can also run from the backend root:

```bash
cd backend/
make up          # starts full stack including chain
```

---

## Adding a new node

1. Create `src/chain/nodes/<name>.py` — implement as an async function returning a state partial:
   ```python
   async def my_node(state: MovieFinderState) -> dict[str, Any]:
       """One-line docstring. Google style."""
       value = state.get("some_field", default_value)
       # ... logic
       return {"result_field": result}
   ```
2. Register the node in `src/chain/graph.py` — add to the builder and connect edges.
3. Update `state.py` if new fields are added to `MovieFinderState`.
4. Write tests in `tests/nodes/test_<name>.py`.
5. Update `docs/architecture/plantuml/04-langgraph-pipeline.puml` and `05-langgraph-statemachine.puml`.

**State rule:** `MovieFinderState` has `total=False` (issue #15). Always use `.get()` with a safe
default when reading fields — never index directly.

---

## Code standards

- `mypy --strict` must pass on every node
- Nodes are pure functions — no shared mutable state between calls
- No `os.getenv()` in node files — read settings from `config.py` (`Pydantic BaseSettings`)
- No `print()` — use `logging.getLogger(__name__)`
- Async all the way — no blocking I/O inside async functions
- Line length: 100

---

## Testing

```bash
make test           # all tests
make test-coverage  # with coverage report
```

- Mock external services (Qdrant, OpenAI, Anthropic, imdbapi) — no real API calls in unit tests
- `pytest --asyncio-mode=auto` is configured — `async def test_*` works without `@pytest.mark.asyncio`
- Coverage must not regress

---

## Environment variables

Copy `backend/chain/.env.example` to `.env` and fill in:

```
ANTHROPIC_API_KEY, OPENAI_API_KEY
QDRANT_URL, QDRANT_API_KEY_RO, QDRANT_COLLECTION_NAME
CLASSIFIER_MODEL, REASONING_MODEL
RAG_TOP_K, MAX_REFINEMENTS, IMDB_SEARCH_LIMIT, CONFIDENCE_THRESHOLD
LANGSMITH_TRACING, LANGSMITH_API_KEY, LANGSMITH_PROJECT  (optional)
```
