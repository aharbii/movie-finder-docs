# Gemini CLI — docs submodule

Foundational mandate for `movie-finder-docs` (`docs/`).

---

## What this submodule does
MkDocs site with architecture diagrams and ADRs.

---

## Architecture diagrams
- **PlantUML:** Edit `.puml` in `architecture/plantuml/`.
- **Structurizr C4:** Edit `architecture/workspace.dsl`.
- **Constraint:** NEVER generate `.mdj` StarUML files programmatically.
- **Build:** Run `./scripts/prepare-docs.sh` from root before `mkdocs serve`.

---

## ADR (Architecture Decision Records)
- Create in `architecture/decisions/` using the template in `index.md`.
- Status: `Proposed` → `Accepted`.

---

## VSCode setup

`docs/.vscode/` — workspace configuration for documentation editing.
- `settings.json`: PlantUML local renderer, Markdown word-wrap, ruler 120
- `extensions.json`: `jebbs.plantuml`, `yzhang.markdown-all-in-one`, `davidanson.vscode-markdownlint`
- PlantUML preview: `Option+D` / `Alt+D` with jebbs.plantuml extension
- Modifying configs: Update `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, and the repo's
  `.github/copilot-instructions.md` after any change.
