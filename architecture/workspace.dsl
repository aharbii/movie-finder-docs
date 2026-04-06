/*
 * Movie Finder — Structurizr C4 Architecture Model
 *
 * Levels covered:
 *   L1 — System Context
 *   L2 — Container diagram
 *   L3 — Component diagram (backend)
 *
 * Render with (from repo root):
 *   docker compose --profile docs up structurizr
 *   open http://localhost:18080
 *
 * Port 18080 avoids conflicts with Jenkins (8080) and FastAPI (8000).
 *
 * Or export to PNG/SVG with the Structurizr CLI:
 *   docker run --rm \
 *     -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
 *     structurizr/cli export \
 *     -workspace /usr/local/structurizr/workspace.dsl \
 *     -format png
 */

workspace "Movie Finder" "AI-powered movie discovery and Q&A" {

    !adrs decisions

    model {

        # =====================================================================
        # Actors
        # =====================================================================
        user = person "End User" "A person looking for a movie they half-remember."

        # =====================================================================
        # External software systems
        # =====================================================================
        qdrantCloud = softwareSystem "Qdrant Cloud" "Managed vector database. Stores text-embedding-3-large (3072-dim) embeddings of the movie corpus. Always the production cluster — no local instance." "External"

        anthropicApi = softwareSystem "Anthropic Claude API" "LLM provider. Claude Haiku used for intent classification and query refinement. Claude Sonnet used for Q&A agent reasoning." "External"

        openAiApi = softwareSystem "OpenAI API" "Embedding provider. text-embedding-3-large used to embed user queries at query time and movie plots at ingestion time." "External"

        imdbApiDev = softwareSystem "imdbapi.dev" "Unauthenticated REST API that provides live IMDb metadata — ratings, posters, credits, plot summaries — for movie enrichment." "External"

        azureKeyVault = softwareSystem "Azure Key Vault" "Stores runtime secrets (API keys, JWT secret, DATABASE_URL). Injected into the backend Container App at startup via managed identity." "External"

        azureContainerRegistry = softwareSystem "Azure Container Registry (ACR)" "Private Docker image registry. Stores tagged images for backend and frontend. Tags: :sha8 (per commit), :latest (main branch), :v1.2.3 (releases)." "External"

        jenkins = softwareSystem "Jenkins" "Self-hosted CI/CD server (Ubuntu + ngrok for GitHub webhook delivery). Runs lint, test, and coverage for per-repo pipelines. Root pipeline builds images and deploys to Azure." "External"

        githubActions = softwareSystem "GitHub Actions" "Cloud CI/CD. Mirrors Jenkins 1:1 — CONTRIBUTION mode (lint + test + coverage reports on PRs) and root pipeline (build + deploy via GitHub Environments for production gate)." "External"

        # =====================================================================
        # Movie Finder Software System
        # =====================================================================
        movieFinder = softwareSystem "Movie Finder" "Fullstack AI application for natural-language movie discovery." {

            # -----------------------------------------------------------------
            # Containers
            # -----------------------------------------------------------------
            angularSpa = container "Angular SPA" "Single-page application served by nginx. Provides the chat interface, session sidebar, movie cards, and authentication forms." "Angular 21 / TypeScript 5.9 / nginx" "Web Browser"

            fastApiBackend = container "FastAPI Backend" "Handles authentication (JWT), session management, and chat. Delegates movie discovery to the LangGraph chain. Streams responses via SSE." "Python 3.13 / FastAPI / asyncpg" {

                # -------------------------------------------------------------
                # Components inside FastAPI Backend
                # -------------------------------------------------------------
                authRouter = component "Auth Router" "POST /auth/register, /auth/login, /auth/refresh, /auth/logout. Issues and validates JWT access tokens (30 min TTL) and refresh tokens (7 days)." "FastAPI Router"

                chatRouter = component "Chat Router" "POST /chat (SSE stream), GET /chat/sessions, GET /chat/{id}/history, DELETE /chat/{id}. Validates JWT, resolves session ownership, delegates to the chain." "FastAPI Router"

                jwtMiddleware = component "JWT Middleware" "Validates Bearer tokens on every authenticated request. Returns 401 on missing/expired token. Returns 403 on session ownership mismatch." "FastAPI Dependency"

                sessionStore = component "Session Store" "Async PostgreSQL client (asyncpg). Persists users, sessions, and messages. Enforces user–session ownership on all reads and deletes." "asyncpg"

                langGraphChain = component "LangGraph Chain" "Compiled Pregel graph. Nodes: RAG Search → IMDb Enrichment → Validation → Presentation → [Confirmation | Refinement | Dead-end] → Q&A Agent. Maximum 3 refinement cycles." "LangGraph / LangChain"

                ragService = component "RAG Service" "Wraps the Qdrant Python client. Encodes user queries with OpenAI embeddings and queries the movies collection. Returns top-K candidates with cosine similarity scores." "qdrant-client / openai"

                imdbApiClient = component "IMDb API Client" "Async HTTP client (httpx + tenacity). Queries imdbapi.dev search and title endpoints. Used by the IMDb Enrichment node to fetch live metadata per candidate." "httpx / pydantic"
            }

            postgresDb = container "PostgreSQL" "Relational database. Stores users, chat sessions, and messages. Azure Database for PostgreSQL Flexible Server in production; local Docker container in development." "PostgreSQL 16" "Database"

            ragIngestionPipeline = container "RAG Ingestion Pipeline" "Offline pipeline run manually or on schedule. Downloads the Kaggle movie dataset, generates OpenAI embeddings, and loads vectors into Qdrant Cloud." "Python 3.13 / pandas / kagglehub / openai / qdrant-client" "Scheduled Job"
        }

        # =====================================================================
        # Relationships — Context level
        # =====================================================================
        user -> movieFinder "Discovers and asks questions about movies via" "HTTPS / SSE"
        movieFinder -> qdrantCloud "Vector similarity search" "HTTPS / Qdrant gRPC"
        movieFinder -> anthropicApi "LLM inference (classification, refinement, Q&A)" "HTTPS"
        movieFinder -> openAiApi "Text embedding at query time" "HTTPS"
        movieFinder -> imdbApiDev "Enriches candidates with live metadata" "HTTPS"
        movieFinder -> azureKeyVault "Fetches runtime secrets at startup" "HTTPS / Managed Identity"
        jenkins -> movieFinder "Builds Docker images and deploys via root pipeline" "Docker push + az CLI"
        jenkins -> azureContainerRegistry "Pushes backend and frontend Docker images" "HTTPS"
        azureContainerRegistry -> movieFinder "Supplies container images at deploy time" "HTTPS"
        githubActions -> movieFinder "Mirrors Jenkins — lint/test per repo + build/deploy from root" "GitHub Environment gated"
        githubActions -> azureContainerRegistry "Pushes Docker images (secondary path)" "HTTPS"

        # =====================================================================
        # Relationships — Container level
        # =====================================================================
        user -> angularSpa "Uses" "HTTPS (port 80)"
        angularSpa -> fastApiBackend "REST + SSE (JWT Bearer)" "HTTPS /api (port 8000)"
        fastApiBackend -> postgresDb "Reads and writes user, session, message data" "asyncpg / TCP 5432"
        fastApiBackend -> qdrantCloud "Vector search via RAG Service" "HTTPS"
        fastApiBackend -> anthropicApi "LLM calls via LangGraph chain" "HTTPS"
        fastApiBackend -> openAiApi "Embedding via RAG Service" "HTTPS"
        fastApiBackend -> imdbApiDev "Movie metadata via IMDb client" "HTTPS"
        ragIngestionPipeline -> openAiApi "Embeds movie plots at ingestion time" "HTTPS"
        ragIngestionPipeline -> qdrantCloud "Upserts vectors into movies collection" "HTTPS"

        # =====================================================================
        # Relationships — Component level (inside FastAPI Backend)
        # =====================================================================
        angularSpa -> authRouter "POST /auth/* (register, login, refresh)" "HTTP/JSON"
        angularSpa -> chatRouter "POST /chat (SSE), GET sessions/history, DELETE session" "HTTP/SSE"
        chatRouter -> jwtMiddleware "Validates Bearer token"
        authRouter -> sessionStore "Creates user, validates credentials, stores refresh token"
        chatRouter -> sessionStore "Reads/writes sessions and messages"
        chatRouter -> langGraphChain "Invokes pipeline, streams events"
        langGraphChain -> ragService "RAG Search node: embed + query Qdrant"
        langGraphChain -> imdbApiClient "IMDb Enrichment node: fetch live metadata"
        langGraphChain -> anthropicApi "Calls Claude for classification, refinement, Q&A"
        ragService -> openAiApi "Generates query embeddings"
        ragService -> qdrantCloud "Similarity search"
        imdbApiClient -> imdbApiDev "Fetches search results + title details"

        # =====================================================================
        # Deployment — Azure
        # =====================================================================
        deploymentEnvironment "Production (Azure)" {

            deploymentNode "Azure" "Microsoft Azure Cloud" {

                deploymentNode "Azure Container Apps Environment" "Managed serverless container runtime. Shared network for frontend ↔ backend communication." {

                    deploymentNode "movie-finder-frontend Container App" "nginx:stable-alpine + Angular bundle. min=1 max=5 replicas. Port 80." {
                        containerInstance angularSpa
                    }

                    deploymentNode "ca-movie-finder Container App" "python:3.13-slim + FastAPI app. min=1 max=4 replicas. Port 8000." {
                        containerInstance fastApiBackend
                    }
                }

                deploymentNode "Azure Database for PostgreSQL Flexible Server" "Managed PostgreSQL 16. Accessible only from within the Container Apps environment network." {
                    containerInstance postgresDb
                }

                deploymentNode "Azure Container Registry (ACR)" "Private image store for all Docker images." {
                    softwareSystemInstance azureContainerRegistry
                }

                deploymentNode "Azure Key Vault" "Stores secrets injected into the backend Container App via managed identity at startup." {
                    softwareSystemInstance azureKeyVault
                }
            }

            deploymentNode "Qdrant Cloud" "External managed vector database service." {
                softwareSystemInstance qdrantCloud
            }

            deploymentNode "Jenkins Server (Ubuntu)" "On-premise Ubuntu VM running Jenkins LTS. Exposed to GitHub via ngrok HTTPS tunnel." {
                softwareSystemInstance jenkins
            }
        }

        deploymentEnvironment "Local Development" {

            deploymentNode "Developer Workstation" {

                deploymentNode "docker compose" "Orchestrates all local services" {

                    deploymentNode "movie-finder-frontend container" "nginx:stable-alpine. Port 80 → host 80. Proxies /api to backend." {
                        containerInstance angularSpa
                    }

                    deploymentNode "movie-finder-backend container" "python:3.13-slim. Port 8000 → host 8000." {
                        containerInstance fastApiBackend
                    }

                    deploymentNode "movie-finder-postgres container" "postgres:16-alpine. Port 5432 → host 5432." {
                        containerInstance postgresDb
                    }
                }
            }

            deploymentNode "Qdrant Cloud (shared)" "The same production Qdrant cluster used in all environments — there is no local Qdrant container." {
                softwareSystemInstance qdrantCloud
            }
        }
    }

    # =========================================================================
    # Views
    # =========================================================================
    views {

        systemContext movieFinder "SystemContext" {
            include *
            autoLayout lr
            title "Movie Finder — System Context"
            description "Shows Movie Finder and its relationships with users and external systems."
        }

        container movieFinder "Containers" {
            include *
            autoLayout lr
            title "Movie Finder — Container Diagram"
            description "Internal containers: Angular SPA, FastAPI Backend, PostgreSQL, RAG Ingestion Pipeline."
        }

        component fastApiBackend "BackendComponents" {
            include *
            autoLayout lr
            title "FastAPI Backend — Component Diagram"
            description "Internal components of the FastAPI backend: routers, middleware, chain, services."
        }

        deployment movieFinder "Production (Azure)" "ProductionDeployment" {
            include *
            autoLayout lr
            title "Movie Finder — Production Deployment (Azure)"
            description "Azure Container Apps, PostgreSQL Flexible Server, ACR, Key Vault, and external services."
        }

        deployment movieFinder "Local Development" "LocalDeployment" {
            include *
            autoLayout lr
            title "Movie Finder — Local Development Deployment"
            description "docker compose stack on a developer workstation."
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Database" {
                shape Cylinder
                background #438dd5
                color #ffffff
            }
            element "Web Browser" {
                shape WebBrowser
            }
            element "Scheduled Job" {
                shape RoundedBox
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
