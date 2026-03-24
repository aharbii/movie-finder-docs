---
title: API Reference
description: Movie Finder REST API — OpenAPI 3.1.0
---

# API Reference

Movie Finder exposes a JSON/SSE REST API served by FastAPI at port 8000.

The full machine-readable specification is at [`api/openapi.yaml`](openapi.yaml).

---

## Interactive API browser

!!! tip "Live try-it-out"
    For live try-it-out with real responses, run `docker compose up --build` and open
    [http://localhost:8000/docs](http://localhost:8000/docs) — FastAPI generates
    interactive Swagger UI automatically from the running application.

The embedded viewer below renders the static specification:

--8<-- "api/openapi.yaml"

```yaml exec="swagger-ui"
url: ./openapi.yaml
```

<!-- mkdocs-swagger-ui-tag renders the spec below -->
<swagger-ui src="./openapi.yaml"/>

---

## Authentication

All `/chat` endpoints require a **Bearer token** obtained from `/auth/login` or `/auth/register`.

| Token | TTL | Usage |
|-------|-----|-------|
| Access token | 30 minutes | `Authorization: Bearer <token>` on every authenticated request |
| Refresh token | 7 days | `POST /auth/refresh` to obtain a new pair before expiry |

On 401, redirect the user to `/login`. On access token expiry, call `/auth/refresh` with the refresh token first.

---

## Endpoint summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/register` | — | Create account, returns JWT pair |
| `POST` | `/auth/login` | — | Authenticate, returns JWT pair |
| `POST` | `/auth/refresh` | — | Exchange refresh token for new JWT pair |
| `POST` | `/chat` | Bearer | Send message, receive SSE stream |
| `GET` | `/chat/sessions` | Bearer | List all sessions for current user |
| `GET` | `/chat/{session_id}/history` | Bearer | Full message history for a session |
| `DELETE` | `/chat/{session_id}` | Bearer | Delete session and all its messages |
| `GET` | `/health` | — | Liveness probe — `{"status": "ok"}` |

---

## SSE streaming — `/chat`

`POST /chat` returns a `text/event-stream` response. Use `fetch()` with a `ReadableStream` decoder — **not** `EventSource`, which is GET-only and cannot carry a request body.

### Stream event shapes

**Token event** (emitted many times, one per streamed chunk):

```json
{ "type": "token", "content": "<chunk>" }
```

**Done event** (emitted exactly once, always last):

```json
{
  "type": "done",
  "session_id": "550e8400-...",
  "reply": "full assistant reply text",
  "phase": "discovery | confirmation | qa",
  "candidates": [...],
  "confirmed_movie": {...}
}
```

### Conversation phases

| Phase | Condition | `done` event extras |
|-------|-----------|---------------------|
| `discovery` | Default — AI gathering preferences | — |
| `confirmation` | AI found candidates | `candidates[]` array |
| `qa` | User confirmed a movie | `confirmed_movie` object |

!!! note "Q&A phase streaming"
    Q&A turns do **not** emit `token` events. The full reply arrives only in the `done` event.
    Always render `done.reply` as a chat message, regardless of phase.

---

## Download the spec

- [openapi.yaml](openapi.yaml) — OpenAPI 3.1.0 YAML
- [swagger-ui.html](swagger-ui.html) — Self-contained Swagger UI (open locally without a server)
