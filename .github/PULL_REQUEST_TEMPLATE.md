## What and why

<!-- What changed and why? Link the issue this addresses. -->

Closes #

## Type of change

- [ ] Architecture diagram update (PlantUML / Structurizr)
- [ ] New or updated Architecture Decision Record (ADR)
- [ ] API reference update (`docs/api/openapi.yaml`)
- [ ] DevOps / setup guide update
- [ ] Service page update (note: service pages are generated — edit the source README instead)
- [ ] Chore (MkDocs config, CI workflow)

## How to test

1. Run `make mkdocs` from the root `movie-finder/` repo
2. Verify the changed pages render correctly at http://localhost:8001
3. Check for broken links in the terminal output

## CI status

The following GitHub Actions check must be green before merge:

| Check           | What it does                                                    |
| --------------- | --------------------------------------------------------------- |
| `docs` workflow | Runs `prepare-docs.sh` + `mkdocs build` — fails on broken links |

## Checklist

### Content

- [ ] `mkdocs build` completes with no warnings about missing files or broken links
- [ ] No content duplicated from a submodule README (those are generated pages — edit the source)
- [ ] Language is clear, accurate, and reflects what is currently implemented

### Diagrams _(if applicable)_

- [ ] `.puml` source files edited — never commit `.png` directly, never generate `.mdj`
- [ ] Diagrams render locally: `plantuml -png docs/architecture/plantuml/<file>.puml`
- [ ] If C4 model relations changed: `architecture/workspace.dsl` updated

### ADR _(if applicable)_

- [ ] ADR status set to `Proposed`
- [ ] `architecture/decisions/index.md` index updated with the new ADR row

### Review

- [ ] PR title follows `docs(scope): summary` (≤72 chars, lowercase)
- [ ] PR description links the issue and discloses the AI authoring tool + model used
- [ ] Any AI-assisted review comment or approval discloses the review tool + model
