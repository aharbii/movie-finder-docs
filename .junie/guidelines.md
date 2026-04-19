# JetBrains AI (Junie) — docs submodule guidelines

This is **`movie-finder-docs`** (`docs/`) — architecture documentation for Movie Finder.
GitHub repo: `aharbii/movie-finder-docs` · Tracker: `aharbii/movie-finder`

> **Primary reference:** `CLAUDE.md` in this directory — read it. It contains the full workflow, checklist, and all diagram rules.

---

## What this submodule contains

MkDocs documentation site with:
- PlantUML architecture diagrams (`architecture/plantuml/01`–`10.puml`)
- Structurizr C4 model (`architecture/workspace.dsl`)
- Architecture Decision Records (`architecture/decisions/`)
- DevOps setup guide, service READMEs, onboarding, contributing

---

## Authoring rules

- Edit `.puml` source files — PNGs are gitignored and generated at build time
- **Never generate `.mdj` StarUML files** — user converts `.puml` to StarUML manually
- Update `workspace.dsl` for any container, component, or inter-system relation change
- ADR format: copy template from `architecture/decisions/index.md`, name `NNNN-short-title.md`

---

## Build and preview

```bash
# From repo root:
make mkdocs        # renders PlantUML + serves at http://localhost:8001
make structurizr   # Structurizr C4 → http://localhost:18080

# VSCode: Alt+D / Option+D for live PlantUML preview (jebbs.plantuml extension)
```

---

## Branching

```
docs/<kebab>    documentation changes
chore/<kebab>   tooling or structure changes
```

Conventional Commits: `docs(architecture): update C4 container diagram`

---

## Key gates before done

- `make mkdocs` runs clean with no broken links
- `.puml` updated for every architectural change
- `workspace.dsl` updated for structural changes
- ADR linked in PR description if a new decision was made
- AI authoring tool + model disclosed in PR description
