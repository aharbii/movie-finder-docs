# Gemini CLI — docs submodule

This is **`movie-finder-docs`** (`docs/`) — part of the Movie Finder project.
GitHub repo: `aharbii/movie-finder-docs` · Parent repo: `aharbii/movie-finder`

> See root GEMINI.md for: full submodule map, GitHub issue/PR hygiene, coding standards, branching strategy, session start protocol.

---

## What this submodule does

MkDocs site with architecture diagrams and ADRs.

---

## Architecture diagrams

- **PlantUML:** Edit `.puml` in `architecture/plantuml/`. PNGs are gitignored — generated at build time.
- **Structurizr C4:** Edit `architecture/workspace.dsl`.
- **Constraint:** NEVER generate `.mdj` StarUML files programmatically.
- **Build:** Run `make mkdocs` from repo root — handles prepare-docs, PlantUML, and serves at :8001.
- **VSCode preview:** `Option+D` / `Alt+D` with `jebbs.plantuml` extension.

---

## ADR (Architecture Decision Records)

- Create in `architecture/decisions/` using the template in `index.md`.
- Name: `NNNN-short-title.md`. Status: `Proposed` → `Accepted`.

---

## VS Code setup

`docs/.vscode/` — workspace configuration for documentation editing.

- `settings.json`: PlantUML local renderer, Markdown word-wrap, ruler 120
- `extensions.json`: `jebbs.plantuml`, `yzhang.markdown-all-in-one`, `davidanson.vscode-markdownlint`

---

## Workflow invariants (docs-specific)

- Gitlink path is `docs` inside `aharbii/movie-finder`. Parent path filters must use `docs`, not `docs/**`.
- Every other submodule's architectural change will require a commit here first — bump the pointer in root after.

### Submodule pointer bump

```bash
# in root movie-finder
git add docs && git commit -m "docs: bump to latest main"
```
