# 0008. LLM and Embedding Provider Factory

Date: 2026-04-19
## Status:
Accepted

## Context
The Movie Finder project relies heavily on Large Language Models (LLMs) and embedding models for its core functionality across two primary sub-repositories:
1. `backend/chain`: The FastAPI runtime executing the LangGraph agent pipeline.
2. `rag/`: The offline ingestion pipeline responsible for vectorizing the dataset.

Initially, both repositories hardcoded dependencies on paid frontier models (Anthropic's `claude-haiku` / `claude-sonnet` for the chain, and OpenAI's `text-embedding-3-large` for embeddings). 

During development, relying exclusively on these paid APIs incurs significant cost and introduces rate-limiting bottlenecks (e.g., TPM/RPM limits during intensive RAG testing or automated QA). Furthermore, developers with capable local hardware (e.g., GPUs with 12GB+ VRAM) had no seamless way to offload inference to free local models (like Ollama, vLLM, or SentenceTransformers) without rewriting application code.

## Decision
We are adopting a unified **Provider Factory Pattern** across the entire project ecosystem. 

1. **Environment-Driven Instantiation:**
   Code must never hardcode a `ChatAnthropic` or `OpenAI` client directly within node logic. Instead, instantiation is abstracted behind factory functions (e.g., `get_reasoning_llm()`, `get_embedding_model()`).
   These factories read dedicated environment variables to determine the provider:
   - `${NODE}_PROVIDER` (e.g., `CLASSIFIER_PROVIDER="ollama"`, `EMBEDDING_PROVIDER="huggingface"`)
   - `${NODE}_MODEL` (e.g., `CLASSIFIER_MODEL="llama4-8b"`, `EMBEDDING_MODEL="BAAI/bge-m3"`)

2. **Strict Pydantic Validation:**
   The `ChainConfig` (and equivalent RAG config) must validate `${NODE}_PROVIDER` against a strict `Literal` whitelist (e.g., `"anthropic", "openai", "groq", "together", "ollama", "google", "huggingface"`) to ensure fail-fast behaviour at startup.

3. **Singleton Caching:**
   To prevent connection pool exhaustion and redundant initialization, factory functions must be decorated with `@lru_cache(maxsize=1)`.

4. **Zero-Collision Qdrant Collection Naming:**
   Because different embedding models produce vectors of different dimensions (and even models of the same dimension have incompatible vector spaces), the Qdrant collection name will no longer be static.
   Both the RAG ingestion pipeline and the backend runtime MUST dynamically resolve the collection name using the format:
   `{QDRANT_COLLECTION_PREFIX}_{sanitized_model_name}_{dimension}`
   *(Example: `movies_bge_m3_1024` or `movies_text_embedding_3_large_3072`)*.

5. **Docker Image Optimization (Optional Dependencies):**
   To prevent bloating the production Docker images, only the default/compatibility SDKs (`langchain-anthropic`, `langchain-openai`) will remain in the core `dependencies`. Heavy or alternative SDKs (`langchain-google-genai`, `sentence-transformers`, `torch`) will be declared in `[project.optional-dependencies]` (e.g., `providers` or `local`). Dockerfiles will use build arguments to conditionally install these groups during development builds.

## Consequences

**Positive:**
- **Zero-Cost Development:** Developers can run the entire stack locally using Ollama and CPU-based embeddings (like BGE-M3).
- **Agility:** Switching from Anthropic to Groq or Google Gemini requires zero code changes, only `.env` updates.
- **Safety:** The dynamic collection naming completely eliminates the risk of dimension mismatch errors or corrupting an existing vector space when testing new embedding models.
- **Image Size:** Production Docker images remain lean by excluding massive local ML libraries unless explicitly requested.

**Negative:**
- **Complexity:** The configuration schema is more verbose. Developers must ensure they have the correct optional dependencies installed if they choose an alternative provider.
- **Coordination:** The backend and the RAG ingestion pipelines must maintain strict parity on how they sanitize model names to generate the Qdrant collection suffix, otherwise the backend will query a non-existent collection.