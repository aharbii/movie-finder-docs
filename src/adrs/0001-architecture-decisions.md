# Architecture Decision Record: ADR-0001
Date: 2024-03-22
Title: Foundation Tech Stack and AI Pattern

## Context
The Movie Finder requires a robust, enterprise-level architecture that can scale, provide highly functional AI interactions, and be independently developed by distinct teams. It needs an AI that can ingest local movie plot data (Qdrant) while pulling rich imagery/metadata from external APIs (IMDBApI). 

## Decision
1. **Repository Structure**: Use separate Git repositories managed as Submodules under a main root workspace locally. This allows atomic CI/CD triggers on Jenkins per service.
2. **AI Pattern**: Utilize a LangChain/LangGraph autonomous agent initialized with specific Tools (RAGTool, IMDBTool). The Agent orchestrates reasoning and API routing, dynamically fetching needed context.
3. **Database**: PostgreSQL handles structured, transactional data (Users, Auth, Chat Memory, and custom Usage/Monitoring telemetry).
4. **Auth**: Custom JWT-based stateless authentication verified exclusively on the FastAPI side.
5. **Frontend UI**: Angular SPA with Tailwind CSS for rapid prototyping and enterprise scaling.

## Consequences
- **Positive**: High separation of concerns; easy feature branching; the Agent can dynamically handle complex conversational turns (e.g., "Oh wait, I meant the movie with Leonardo DiCaprio").
- **Negative**: Submodules introduce slightly complex developer checkout flows (`git clone --recursive`). Custom monitoring in Postgres requires additional SQL schema maintenance over using managed platforms like DataDog or LangSmith.
