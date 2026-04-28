# MCP Tooling Developer Contract

The `movie-finder` workspace uses the Model Context Protocol (MCP) to give AI coding agents
(Claude Code, Cursor, JetBrains AI, Copilot) deep contextual awareness of the local
development environment and external services.

All project-level MCP servers are configured in `.mcp.json` at the repo root.
Claude Code picks this up automatically when the root workspace is open.

---

## Local MCP Servers (project-built)

These run as subprocesses on the developer's machine via `stdio` transport.
They are never deployed to Azure or exposed via HTTP.

**Stack:** Python 3.13, `uv`, `fastmcp`, `pydantic` v2.
**Code standards:** 100-char line limit (`ruff`), strict type checking (`mypy --strict`).

| Server               | Path                   | Status    | Purpose                                            |
| -------------------- | ---------------------- | --------- | -------------------------------------------------- |
| `qdrant-evaluator`   | `mcp/qdrant-explorer/` | ✅ Ready  | Query Qdrant, embed text, evaluate RAG retrieval   |
| `langgraph-inspector`| `mcp/langgraph-inspector/` | 🔧 Planned | Inspect LangGraph state and Postgres checkpointer |
| `schema-inspector`   | `mcp/schema-inspector/`| 🔧 Planned | Postgres schema assistant — introspect DDL + data  |
| `imdb-sandbox`       | `mcp/imdb-sandbox/`    | 🔧 Planned | IMDb API prompt sandbox for chain development      |

### qdrant-evaluator (ready)

**GitHub repo:** `aharbii/movie-finder-mcp-qdrant`

**Required env vars:**
```
QDRANT_URL                # Qdrant Cloud cluster URL
QDRANT_API_KEY_RO         # Read-only Qdrant API key
VECTOR_COLLECTION_PREFIX  # Target prefix; final name is prefix_model_dimension
EMBEDDING_PROVIDER        # e.g. openai or ollama
EMBEDDING_MODEL           # e.g. text-embedding-3-large
OPENAI_API_KEY            # When EMBEDDING_PROVIDER=openai
```

**Available tools:**
- `qdrant_search` — semantic search by query string
- `embed_text` — embed text and inspect the vector
- `get_collection_status` — check collection health and point count
- `get_movie_data` — fetch a specific movie payload by ID
- `get_similar_movies_by_title` — find semantically similar movies
- `scroll_movies_by_director` — filter by director using payload filter
- `filtered_search` — search with metadata filters
- `compare_cosine_similarity` — compare two query embeddings

### langgraph-inspector (planned)

**Purpose:** Read active LangGraph thread states from the Postgres checkpointer.
Useful for debugging multi-turn conversations and validating state transitions.

**Required env vars:** `DATABASE_URL`

### schema-inspector (planned)

**Purpose:** Provide real-time awareness of PostgreSQL table structures, indexes,
and Alembic migration levels. Useful when writing or reviewing database code.

**Required env vars:** `DATABASE_URL`

### imdb-sandbox (planned)

**Purpose:** Query the IMDb API interactively to help design prompts and validate
enrichment logic in the chain. Useful when tuning the `enrich_imdb` node.

**Required env vars:** `IMDBAPI_BASE_URL` (or equivalent)

---

## External MCP Servers

These are configured in `.mcp.json` and require separate packages installed globally
or run via `npx`/`uvx`.

| Server      | Package                                | Purpose                                          |
| ----------- | -------------------------------------- | ------------------------------------------------ |
| `github`    | `@modelcontextprotocol/server-github`  | Issues, PRs, code search across all repos        |
| `postgres`  | `@modelcontextprotocol/server-postgres`| Live DB queries against the PostgreSQL store     |
| `kaggle`    | `kaggle-mcp` (uvx)                     | Dataset management and Kaggle API operations     |
| `langsmith` | `langsmith-mcp` (uvx)                  | LangSmith traces, evaluations, prompts           |
| `azure`     | `@azure/mcp`                           | Azure resource inspection and management         |

**Required env vars for external MCPs:**
```
GITHUB_PERSONAL_ACCESS_TOKEN   # GitHub API access (fine-grained PAT recommended)
DATABASE_URL                    # postgres://user:pass@localhost:5432/dbname
KAGGLE_API_TOKEN                # Kaggle API token (from kaggle.com/account)
LANGSMITH_API_KEY               # LangSmith API key
LANGSMITH_PROJECT               # LangSmith project name
```

Add these to your local `.env` file (never commit it).

---

## IDE Configuration

`.mcp.json` at the repo root is automatically read by Claude Code and Cursor when the
root workspace is open. For JetBrains AI and GitHub Copilot, configure MCP servers
in the respective IDE settings UI.

For Cursor specifically: the `.cursorrules` file at the root also loads automatically
and provides project-specific AI hints.
