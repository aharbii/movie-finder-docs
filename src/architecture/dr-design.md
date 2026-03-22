# Disaster Recovery (DR) Strategy

The system is designed with a High Availability (HA) approach prioritizing RTO (Recovery Time Objective) and RPO (Recovery Point Objective):

## 1. Database Layer (PostgreSQL & Qdrant)
- **PostgreSQL**: Deployed in a Multi-AZ cluster with synchronous replication. Daily automated snapshots are sent to a secure cold-storage bucket (e.g., S3/GCS).
  - *RPO*: < 5 minutes via WAL logs.
  - *RTO*: Automatic failover within 1-2 minutes.
- **Qdrant**: Snapshots of the Wikipedia embeddings collections are backed up weekly. Since the source of truth is the static CSV file, it can be re-indexed if completely lost.
  - *RPO*: Negligible (data is semi-static).
  - *RTO*: ~30 minutes to spin-up fresh Qdrant and run the Jenkins ingestion pipeline.

## 2. Application Layer (FastAPI & Angular)
- **Stateless Design**: Neither the agent container nor the Angular container hold persistent state. All conversational memory lives in Postgres.
- **Autoscaling**: Deployed behind a Load Balancer via Kubernetes or cloud-native container services (e.g., GCP Cloud Run, Azure Container Apps).
- **Multi-Region Active/Passive Failover**: In case the primary region fails, DNS routing switches to a secondary region which boots the stateless application images connected to cross-region replicated databases.

## 3. External Dependencies (LLMs & IMDBApi)
- Circuit breakers (e.g., resilience4j / Tenacity python retry logs) handle temporary outages of the OpenAI API or IMDBApi.
- If OpenAI is down, an automatic fallback to Anthropic is recommended in the Agent's routing logic.
