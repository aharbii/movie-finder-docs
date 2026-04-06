# ADR-004: Standalone Repositories for MCP Servers

**Date:** 2026-04-05
**Status:** Accepted

## Context

With the decision to use MCP for internal tooling (ADR-003), we need to determine where these MCP servers should live. Integrating them into the existing `backend/` or `backend/chain/` submodules would introduce conflicting dependencies (e.g., `mcp` and `fastmcp` packages) and complicate the existing `uv.lock` files, which are strictly for production application dependencies.

## Decision

We will create a new parent directory `mcp/` at the workspace root. Each MCP server (e.g., `qdrant-explorer`, `langgraph-inspector`, `schema-inspector`, `imdb-sandbox`) will be a separate Git submodule with its own `uv.lock`, isolated dependencies, and separate testing lifecycle.

## Consequences

- **Positive**: Strict boundary enforcement. The production FastAPI and LangGraph environments remain untainted by DX tools. Dependency resolution is isolated and faster.
- **Negative**: Increases the number of submodules in the `movie-finder` project, requiring developers to ensure they pull all submodules upon checkout.
