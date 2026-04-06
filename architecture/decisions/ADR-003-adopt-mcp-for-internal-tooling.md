# ADR-003: Adopt Model Context Protocol for Internal AI Tooling

**Date:** 2026-04-05
**Status:** Accepted

## Context

We need a standardized way to provide AI assistants (like Cursor, Claude Desktop, and LangGraph pipelines) with contextual awareness of our local development state, database schemas, and external API integrations (like Qdrant and IMDb) without bloating the production FastAPI server. Exposing developer utilities via production HTTP endpoints introduces security risks and mixes deployment concerns with developer experience (DX).

## Decision

We will adopt the Model Context Protocol (MCP) exclusively for internal developer experience and AI tooling. These MCP servers will run locally via `stdio` and will not be deployed to production or packaged in our release containers.

## Consequences

- **Positive**: Complete isolation of DX tooling from production code. Developers and AI agents can securely access local state (e.g., Postgres checkpointer, Qdrant vectors) via standard MCP integrations.
- **Negative**: Requires developers to manage additional local Python processes (via `uv` and `fastmcp`) during development.
