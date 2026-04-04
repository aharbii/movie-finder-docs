---
title: Architecture Decision Records
description: Log of significant architectural decisions for Movie Finder
---

# Architecture Decision Records

Architecture Decision Records (ADRs) document the significant choices made during the design and evolution of the Movie Finder system. Each record captures the context, the decision, and the consequences so that future contributors understand _why_ the system is built the way it is.

## ADR index

| ID                                                   | Title                                                                                      | Status   | Date    |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------ | -------- | ------- |
| [ADR-001](ADR-001-initial-architecture.md)           | Initial architecture — tech stack and repository structure                                 | Accepted | 2025-Q4 |
| [ADR-002](ADR-002-docker-only-developer-contract.md) | Docker-only developer contract — standardised Makefile targets across all Python sub-repos | Accepted | 2026-Q1 |

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

Create a new file `ADR-NNN-short-title.md` in this directory using the template below. Add it to the index table above.

```markdown
# ADR-NNN: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN

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
