---
title: Architecture Decision Records
description: Log of significant architectural decisions for Movie Finder
---

# Architecture Decision Records

Architecture Decision Records (ADRs) document the significant choices made during the design and evolution of the Movie Finder system. Each record captures the context, the decision, and the consequences so that future contributors understand *why* the system is built the way it is.

## ADR index

| ID | Title | Status | Date |
|----|-------|--------|------|
| [ADR-001](ADR-001-initial-architecture.md) | Initial architecture — tech stack and repository structure | Accepted | 2025-Q4 |

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

| Status | Meaning |
|--------|---------|
| Proposed | Under discussion |
| Accepted | Agreed upon and implemented |
| Deprecated | No longer relevant but kept for historical context |
| Superseded | Replaced by a later ADR (reference it) |
