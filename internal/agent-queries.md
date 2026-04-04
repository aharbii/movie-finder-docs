# Component Agent Queries

These prompts address open questions discovered during documentation. Share each with the relevant agent.

---

## Backend Agent

**Send this to the backend agent:**

---

I am the documentation agent for the Movie Finder project. I have created architecture documentation based on what I can observe in the codebase. I have several gaps that only the backend team can confirm. Please answer each question precisely — do not infer or assume. If something is not implemented or not yet decided, say so explicitly.

**1. PostgreSQL schema**

What are the exact table names, column names, and types for the relational database?
I need this to document the data model accurately in `architecture.mdj` and `ARCHITECTURE.md`.
If there are migration files or a schema file, please share the contents.

**2. Health endpoint behaviour**

Does `GET /health` check database connectivity before returning `{"status": "ok"}`, or does it return `{"status": "ok"}` unconditionally (pure liveness probe)?
If it checks the database, what does it return on failure?

**3. Missing or undocumented endpoints**

The `docs/openapi.yaml` documents these endpoints:

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /chat` (SSE)
- `GET /chat/sessions`
- `GET /chat/{session_id}/history`
- `DELETE /chat/{session_id}`
- `GET /health`

Are there any endpoints that exist in the codebase but are NOT listed above?
Common omissions to check: `GET /auth/me`, `POST /auth/logout`, any `/admin` endpoints.

**4. LangGraph chain state transitions**

What are the exact conditional edges in the compiled LangGraph graph?
Specifically:

- What condition routes from `validation` to `refinement` vs `presentation`?
- What is the confidence threshold below which a candidate is filtered?
- Can a user explicitly reject all candidates, and if so, what node handles that?
- After the Q&A agent, does the graph end or can the user change their confirmed movie?

**5. infrastructure/ submodule**

The `infrastructure/` submodule at the repo root is empty. Is this:
a) Intentional — IaC was decided to be kept in `backend/deploy/provision.sh` only?
b) Work in progress — the team plans to add Terraform/Bicep files here?
c) An oversight — the submodule was registered but never populated?

This affects whether I document it as a future placeholder or remove it from the architecture docs.

**6. LangSmith tracing**

The `.env.example` has `LANGCHAIN_TRACING_V2=false`. Is LangSmith tracing currently working and tested, or is it an aspirational feature? If working, what project name and entity are used?

**7. IMDB_API_KEY in Key Vault**

`docs/devops-setup.md §12` lists `IMDB-API-KEY` as a Key Vault secret, but `backend/README.md` states the IMDb API requires no authentication. Is `IMDB_API_KEY` actually used anywhere in the codebase, or is it an artefact from a previous version?

---

## Frontend Agent

**Send this to the frontend agent:**

---

I am the documentation agent for the Movie Finder project. I am writing contribution guidelines and onboarding documentation for the Angular frontend. Please answer each question precisely — do not infer or assume.

**1. Angular routes**

What are the exact route paths defined in `app.routes.ts`?
I need the full route table: path, component, guards, and any lazy-loaded modules.

**2. TypeScript interfaces**

What interfaces are defined in `core/models.ts`?
Please share the exact interface names and their fields so I can document the frontend data model accurately.

**3. Auth token refresh strategy**

The `auth.interceptor.ts` injects the Bearer token on every request. What happens when it receives a 401 response?

- Does it automatically call `/auth/refresh` and retry the original request?
- Or does it redirect to `/login` immediately?
- Is there a token expiry check before the request is sent (proactive refresh)?

**4. Session management in the Angular app**

Where is the access token stored — `localStorage`, `sessionStorage`, or memory (a service property)?
Where is the refresh token stored?
This affects the security section of the contribution guide.

**5. Test coverage percentage**

What is the current test coverage percentage for the frontend?
If you can run `npm run test:ci`, please share the output — I want to set a documented baseline in the CONTRIBUTING guide.

**6. SSE reconnect behaviour**

If the SSE connection is interrupted mid-stream (e.g., network drop), does the frontend attempt to reconnect? If so, how?

**7. Proxy configuration**

`proxy.conf.js` (and/or `proxy.conf.json`) routes frontend API calls. What paths are proxied to the backend?
Is it only `/api/**`, or also specific paths like `/auth/**`, `/chat/**`, `/health`?

**8. Angular CLI version**

Is Angular CLI installed globally or only as a local dev dependency (`node_modules/.bin/ng`)? The contribution guide should tell new developers how to run `ng` commands.
