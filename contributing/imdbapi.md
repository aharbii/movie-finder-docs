---
title: IMDb API Client Contributing Guide
description: Contributing to the IMDb API client (imdbapi-client)
---

# Contributing to the IMDb API Client

This guide covers working on `backend/chain/imdbapi/` — the async HTTP client for imdbapi.dev.
Repo: `aharbii/imdbapi-client`

For cross-cutting conventions see the [Contributing Overview](index.md).

---

## What this library does

`imdbapi-client` is an adapter that wraps the unauthenticated [imdbapi.dev](https://imdbapi.dev) REST API.
It maps raw HTTP responses to internal domain types so that chain nodes never see raw HTTP.

Two endpoints are used:

| imdbapi.dev endpoint       | Purpose                                       |
| -------------------------- | --------------------------------------------- |
| `GET /search?q=<title>`    | Search for movies by title — returns a list   |
| `GET /title/<imdb_id>`     | Fetch full metadata for a known IMDb ID       |

The client is imported by `movie-finder-chain` as a path dependency.

---

## Development setup

From `backend/chain/imdbapi/`:

```bash
make dev         # build + start dev container
make test        # run pytest inside Docker
make lint        # ruff check + format check
make typecheck   # mypy --strict
make pre-commit  # all hooks
```

---

## Key design rules

- **Adapter pattern** — callers receive domain types (`IMDbMovie`, `IMDbSearchResult`), never raw `httpx.Response` objects
- **No authentication** — imdbapi.dev requires no API key; never add one
- **Retry with tenacity** — transient failures are retried; keep base delay short to avoid blocking the SSE stream (see issue #8)
- **Serialized search calls** — concurrency=1 on search requests avoids triggering Cloudflare rate limiting
- **Async only** — `httpx.AsyncClient`, never `httpx.Client`

---

## Adding support for a new endpoint

1. Add the request/response Pydantic models in `src/imdbapi/models.py`
2. Add the method to `src/imdbapi/client.py` — keep it async, return a domain type
3. Write tests in `tests/test_client.py` — mock `httpx.AsyncClient` responses
4. Update the adapter interface if the chain consumes the new method

---

## Code standards

- `mypy --strict` must pass
- All public methods have Google-style docstrings
- No `print()` — use `logging`
- Catch specific exception types (e.g., `httpx.TimeoutException`, `httpx.HTTPStatusError`) — no bare `except`
- Line length: 100
