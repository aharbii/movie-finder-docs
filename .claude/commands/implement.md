# Implement Issue — movie-finder-docs

**Repo:** `aharbii/movie-finder-docs`
**Parent tracker:** `aharbii/movie-finder`
**Build:** `./scripts/prepare-docs.sh && mkdocs build` (from repo root)

Implement GitHub issue #$ARGUMENTS from `aharbii/movie-finder-docs`.

---

## Step 1 — Read the child issue

```bash
gh issue view $ARGUMENTS --repo aharbii/movie-finder-docs
```

Find the **Agent Briefing** section. If absent, ask the user to add it before proceeding.

---

## Step 2 — Read the parent issue for full context

```bash
gh issue view [PARENT_NUMBER] --repo aharbii/movie-finder
```

---

## Step 3 — Read only the files listed in the Agent Briefing

---

## Step 4 — Create the branch

```bash
git checkout main && git pull
git checkout -b docs/[kebab-case-title]
```

---

## Step 5 — Implement

Docs-specific rules:
- Run `./scripts/prepare-docs.sh` before `mkdocs serve` — it copies submodule READMEs and renders PNGs
- PlantUML source lives in `architecture/plantuml/*.puml` — always update `.puml` files, never commit generated PNGs
- Structurizr DSL lives in `architecture/workspace.dsl` — update when components or relations change
- ADRs live in `architecture/decisions/` — copy the template from `index.md`
- Never generate `.mdj` StarUML files programmatically
- Rulers: 120 chars for docs Markdown
- CHANGELOG.md must be updated under [Unreleased]

---

## Step 6 — Verify build

```bash
./scripts/prepare-docs.sh
mkdocs build --strict
```

---

## Step 7 — Commit

```bash
git add [only changed files — never git add -A]
git commit -m "$(cat <<'EOF'
docs(scope): short summary

[why]

Closes #$ARGUMENTS
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Step 8 — Open PR

```bash
gh pr create \
  --repo aharbii/movie-finder-docs \
  --title "docs(scope): short summary" \
  --body "$(cat <<'EOF'
[PR body]

Closes #$ARGUMENTS
Parent: [PARENT_ISSUE_URL]

---
> AI-assisted implementation: Claude Code (claude-sonnet-4-6)
EOF
)"
```

---

## Step 9 — Cross-cutting comments

Comment on related issues (from Agent Briefing), the child issue, and the parent issue.
