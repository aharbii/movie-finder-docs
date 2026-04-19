# Session Start — movie-finder-docs

Run these checks in parallel, then give a prioritised summary. Do not read any source files.

```bash
gh issue list --repo aharbii/movie-finder-docs --state open --limit 20 \
  --json number,title,labels,assignees
```

```bash
gh pr list --repo aharbii/movie-finder-docs --state open \
  --json number,title,state,labels,headRefName
```

```bash
gh issue list --repo aharbii/movie-finder --state open --limit 5 \
  --json number,title,labels
```

```bash
git status && git log --oneline -5
```

Then summarise:

- **Open issues in this repo** — number, title, label
- **Open PRs** — which are ready to review, which are blocked
- **Parent tracker issues** — any that involve documentation or architecture diagrams
- **Current branch and uncommitted changes**
- **Recommended next action** — one specific thing

Note: `docs/` is commonly updated last in a cross-repo chain — check if any sibling repo has
merged changes that still need diagram or ADR updates here.

Keep the summary under 20 lines. Do not propose solutions yet.
