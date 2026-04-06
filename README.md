# Movie Finder — Documentation

This directory is the canonical documentation source for the Movie Finder project and serves as the `docs_dir` for [MkDocs](https://www.mkdocs.org/).

---

## Folder structure

```
docs/
├── index.md                          MkDocs home page
├── onboarding.md                     New developer guide (generated from root ONBOARDING.md)
├── api/
│   ├── index.md                      API overview + embedded Swagger UI
│   ├── openapi.yaml                  OpenAPI 3.1.0 machine-readable spec
│   └── swagger-ui.html               Self-contained Swagger UI (open locally)
├── architecture/
│   ├── index.md                      Architecture narrative + all diagrams
│   ├── workspace.dsl                 Structurizr C4 model
│   ├── architecture.mdj              StarUML class + sequence diagrams
│   └── decisions/
│       ├── index.md                  ADR register
│       └── 0001-*.md              Architecture Decision Records
├── contributing/
│   ├── index.md                      Root contribution guide (generated)
│   ├── backend.md                    Backend contribution guide (generated)
│   └── frontend.md                   Frontend contribution guide (generated)
├── devops/
│   └── setup.md                      Jenkins + Azure platform setup guide
├── services/
│   ├── index.md                      Service map and dependency overview
│   ├── backend.md                    Backend service docs (generated)
│   ├── frontend.md                   Frontend service docs (generated)
│   ├── chain.md                      LangGraph chain docs (generated)
│   ├── imdbapi.md                    IMDb client docs (generated)
│   └── rag-ingestion.md              RAG ingestion docs (generated)
└── internal/
    └── agent-queries.md              Open questions for component agents
```

Files marked _(generated)_ are copied from the relevant submodule README at build time by `scripts/prepare-docs.sh` or the GitHub Actions workflow. They are not committed to this repository.

---

## Viewing the documentation

### Option A — MkDocs (full site, recommended)

```bash
# From the repo root — builds everything and serves with live-reload
make mkdocs
# Open: http://localhost:8001
```

`make mkdocs` runs `scripts/prepare-docs.sh` (copies submodule READMEs, renders PlantUML PNGs) and then starts MkDocs — all inside the Docker container. No local Python or PlantUML install required.

### Option B — GitHub Pages

The documentation site is automatically built and deployed to GitHub Pages on every push to `main` via the `.github/workflows/docs.yml` workflow.

### Option C — Browse files directly

All committed files render correctly on GitHub. Generated pages show a note linking to the original source.

---

## API viewer

```bash
# Open the Swagger UI in your browser (no server needed)
open docs/api/swagger-ui.html        # macOS
xdg-open docs/api/swagger-ui.html   # Linux
```

---

## Architecture diagrams

### Structurizr (C4 model)

```bash
# Via docker compose (from repo root)
docker compose --profile docs up structurizr
# Open: http://localhost:18080

# Or standalone (port 18080 avoids conflicts with Jenkins:8080 and FastAPI:8000)
docker run -it --rm -p 18080:8080 \
  -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
  structurizr/lite
```

### StarUML

1. Install [StarUML](https://staruml.io)
2. File → Open → `docs/architecture/architecture.mdj`

---

## Document ownership

| Document                        | Owner              | Update trigger               |
| ------------------------------- | ------------------ | ---------------------------- |
| `api/openapi.yaml`              | Backend / App team | Any API change               |
| `architecture/workspace.dsl`    | Architecture lead  | New containers or flows      |
| `architecture/architecture.mdj` | Architecture lead  | New classes or sequences     |
| `architecture/decisions/*.md`   | Proposing team     | New significant decision     |
| `devops/setup.md`               | DevOps / Platform  | Infrastructure or CI changes |
