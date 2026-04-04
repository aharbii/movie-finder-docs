# Review PR — movie-finder-docs

**Repo:** `aharbii/movie-finder-docs`

Post findings as a comment only. Do not submit a GitHub review status.
The human decides whether to merge.

---

## Step 1 — Read PR, issue, and diff

```bash
gh pr view $ARGUMENTS --repo aharbii/movie-finder-docs
gh issue view [LINKED_ISSUE] --repo aharbii/movie-finder-docs
gh pr diff $ARGUMENTS --repo aharbii/movie-finder-docs
```

---

## Blocking findings

**Docs-specific:**

- PNG files committed (PNGs are gitignored — only `.puml` source files)
- `.mdj` StarUML file generated programmatically (manual-only format)
- `mkdocs build --strict` fails (check if noted in PR)
- PlantUML `.puml` file not updated when architecture changed
- Structurizr `workspace.dsl` not updated when components/relations changed
- ADR does not follow the template from `architecture/decisions/index.md`

**PR hygiene:** AI disclosure missing, issue not linked, Conventional Commits not followed.

---

## Post as a comment

```bash
gh pr comment $ARGUMENTS --repo aharbii/movie-finder-docs \
  --body "[review comment body]"
```

```
## Review — [date]
Reviewed by: [tool and model]

### Verdict
PASS — no blocking findings. Human call to merge.
— or —
BLOCKING FINDINGS — must fix before merge.

### Blocking findings
[file] — [issue and fix]

### Non-blocking observations
[observation]

### Cross-cutting gaps
[any item not handled and not noted in PR body]
```
