---
title: AI Agent Queries
description: How to use AI coding agents effectively within the Movie Finder project
---

# AI Agent Queries

This page describes how to work with the AI coding agents configured in this project and how to formulate effective queries for common development tasks.

---

## Configured agents

| Agent             | Context file                      | Primary use case                                   |
| ----------------- | --------------------------------- | -------------------------------------------------- |
| Claude Code       | `CLAUDE.md` (per repo)            | Interactive development, issue creation, PRs       |
| Gemini CLI        | `GEMINI.md` (per repo)            | Fallback when Claude quota is hit; research        |
| OpenAI Codex CLI  | `AGENTS.md` + `ai-context/prompts/` | Scripted implementation via copy-paste prompts   |
| GitHub Copilot    | `.github/copilot-instructions.md` | IDE inline suggestions                             |
| JetBrains AI      | `.junie/guidelines.md`            | JetBrains IDE assistant                            |

---

## MCP servers available to Claude Code

Claude Code has the following MCP servers configured in `.mcp.json`:

| Server            | Status   | What it gives Claude                                   |
| ----------------- | -------- | ------------------------------------------------------ |
| `qdrant-evaluator` | ✅ Ready | Search the Qdrant movie collection, compare embeddings |
| `github`          | ✅ Ready | Read issues, PRs, files; create issues and comments    |
| `postgres`        | ✅ Ready | Query the local PostgreSQL database directly           |
| `kaggle`          | ✅ Ready | Browse datasets, check notebook outputs                |
| `langsmith`       | 🔧 Opt-in | Trace LangGraph runs, compare evaluations             |
| `azure`           | 🔧 Opt-in | Query Azure resources, Container Apps, Key Vault      |

See [MCP Tooling](mcp-tooling.md) for setup instructions.

---

## Slash commands (Claude Code)

Run these from the appropriate workspace:

| Command                       | Where to run            | What it does                                              |
| ----------------------------- | ----------------------- | --------------------------------------------------------- |
| `/session-start`              | Root workspace          | Quick status: open issues, branch, recent commits        |
| `/create-issue [description]` | Root workspace          | Creates a GitHub issue following project conventions     |
| `/implement [issue-number]`   | **Submodule workspace** | Implements the specified issue with context from CLAUDE.md |
| `/review-pr [pr-number]`      | **Submodule workspace** | Reviews a PR against project standards                   |
| `/bump-submodule [path]`      | Root workspace          | Creates the pointer-bump commit after a submodule merge  |

---

## Effective query patterns

### Finding a bug

Give Claude the error message, the file path, and what you expected to happen:

```
The test at backend/app/tests/test_auth.py:45 fails with:
  AssertionError: 401 != 200
I expected the refresh endpoint to return 200 when given a valid refresh token.
The refresh token is being read from the Authorization header.
```

### Implementing a feature

Reference the issue number and attach the Agent Briefing:

```
Implement issue aharbii/movie-finder#N.
The Agent Briefing is in the issue body — read it before touching any code.
Start with /session-start to confirm the branch state.
```

### Architecture questions

Ask about specific files rather than the whole system:

```
In backend/chain/src/chain/graph.py, how does the router decide between
the refinement node and the dead-end node? Walk me through the edge conditions.
```

### Cross-repo impact analysis

Use the cross-cutting checklist in CLAUDE.md:

```
I'm adding a new field `imdb_poster_url` to the done event in the SSE stream.
Walk me through the cross-cutting checklist for this change — which repos are affected
and what exactly needs to change in each one?
```

---

## Agent Briefing requirement

**Every GitHub issue handed to an agent must have an `## Agent Briefing` section.**

Without it, the agent will speculatively explore the codebase to find what the briefing would have told it — burning quota and potentially making wrong assumptions.

Template: `ai-context/issue-agent-briefing-template.md`

The briefing must include:

- Which files to read first
- Which patterns to follow
- What not to touch
- Acceptance criteria

---

## Context file maintenance

When you add a new pattern, tool, or workflow:

1. Update `CLAUDE.md` in the affected repo(s)
2. Mirror the change to `GEMINI.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.junie/guidelines.md`
3. Update `.claude/commands/` if a slash command is affected
4. Update `ai-context/prompts/` for Codex/Gemini copy-paste prompts

See CLAUDE.md → **Cross-cutting change checklist item 10a** for the full list.
