# Architecture Decision Records

Date: 2025-10-01
## Status
Accepted

Architecture Decision Records (ADRs) document the significant choices made during the design and evolution of the Movie Finder system. Each record captures the context, the decision, and the consequences so that future contributors understand _why_ the system is built the way it is.

## ADR index

| ID                                                      | Title                                                                                      | Status   | Date       |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------ | -------- | ---------- |
| [0001](0001-initial-architecture.md)                    | Initial architecture — tech stack and repository structure                                 | Accepted | 2025-Q4    |
| [0002](0002-docker-only-developer-contract.md)          | Docker-only developer contract — standardised Makefile targets across all Python sub-repos | Accepted | 2026-Q1    |
| [0003](0003-adopt-mcp-for-internal-tooling.md)          | Adopt Model Context Protocol for Internal AI Tooling                                       | Accepted | 2026-04-05 |
| [0004](0004-standalone-mcp-repositories.md)             | Standalone Repositories for MCP Servers                                                    | Accepted | 2026-04-05 |
| [0005](0005-github-actions-mirror-and-root-pipeline.md) | GitHub Actions CI mirror and centralised root build pipeline                               | Accepted | 2026-04-06 |
| [0006](0006-terraform-iac.md)                           | Terraform IaC — Azure primary, multi-cloud extensible                                      | Accepted | 2026-04-06 |
| [0007](0007-persistent-langgraph-checkpointing.md)      | Persistent LangGraph checkpointing owned by the backend runtime                            | Accepted | 2026-04-04 |
| [0008](0008-llm-and-embedding-provider-factory.md)     | LLM and Embedding Provider Factory                                                         | Accepted | 2026-04-19 |

## When to write an ADR

Write an ADR for any decision that a future contributor would ask "why did they do it this way?" about. Specifically:

- Adopting or removing an **external dependency or cloud service**
- Changing the **tech stack** at any layer (language, framework, database, vector store)
- Introducing a **new design pattern** project-wide
- Any **auth or security model** change
- Significant **API contract** decisions (new endpoint shape, breaking change)
- **Infrastructure or deployment** topology changes
- Anything debated in a PR where the outcome was non-obvious

If you are unsure, write the ADR as `Proposed` and let the review discussion determine whether it warrants a record.

---

## How to write a new ADR

Create a new file `NNNN-short-title.md` in this directory using the template below. Add it to the index table above.

```markdown
# NNNN. Title

Date: NNNN-NN-NN
## Status:
Proposed | Accepted | Deprecated | Superseded by NNNN

## Context

Why did we need to make a decision? What problem were we solving?

## Decision

What did we decide to do?

## Consequences

What are the positive and negative outcomes of this decision?
What becomes easier? What becomes harder?
```

**Status definitions:**

| Status     | Meaning                                            |
| ---------- | -------------------------------------------------- |
| Proposed   | Under discussion                                   |
| Accepted   | Agreed upon and implemented                        |
| Deprecated | No longer relevant but kept for historical context |
| Superseded | Replaced by a later ADR (reference it)             |
