# AI Context — movie-finder-docs

Shared reference for AI agents working in this repo standalone.

## Available slash commands (Claude Code)

Open `docs/` as your workspace, then type `/`:

| Command                     | Usage                    |
| --------------------------- | ------------------------ |
| `/implement [issue-number]` | Implement a docs issue   |
| `/review-pr [pr-number]`    | Review a PR in this repo |

## Prompts (Codex CLI / Gemini CLI / Ollama)

- `ai-context/prompts/implement.md` — implementation workflow for this repo
- `ai-context/prompts/review-pr.md` — review workflow

Usage:

```bash
cat ai-context/prompts/implement.md
gh pr diff N --repo aharbii/movie-finder-docs > /tmp/pr.txt
cat /tmp/pr.txt | codex "$(cat ai-context/prompts/review-pr.md)"
```

## Important docs-specific rules

- Run `./scripts/prepare-docs.sh` before `mkdocs serve` or `mkdocs build`
- PlantUML `.puml` files in `architecture/plantuml/` are the source of truth — never commit PNGs
- Never generate `.mdj` StarUML files programmatically (manual-only)
- Structurizr DSL: `architecture/workspace.dsl`

## Issue hierarchy

Parent repo: `aharbii/movie-finder`.
Issues in this repo are child issues of `movie-finder`.

## Agent Briefing

Every issue must have an `## Agent Briefing` section before implementation.
Template: `ai-context/issue-agent-briefing-template.md`
