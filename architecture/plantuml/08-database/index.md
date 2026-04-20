---
title: Database Design
description: PostgreSQL 16 entity-relationship diagram for Movie Finder — full schema with indexes, JSONB types, Alembic migration tracking, and refresh token revocation.
---

# Database Design

PostgreSQL 16 entity-relationship diagram reflecting the **target schema**: Alembic-managed migrations, composite indexes on all foreign keys, JSONB `confirmed_movie`, refresh token revocation flag, and expression index on `movie_data->>'imdb_id'`.

---

## 01 — Entity-Relationship Diagram

Tables: `users`, `sessions`, `messages`, `confirmed_movies`, `refresh_tokens`, `alembic_version`. All primary keys, foreign keys with `ON DELETE CASCADE`, data types, check constraints, unique constraints, and indexes are modeled.

![PostgreSQL ER Diagram](01-db-entity-relationship.png)

!!! note "Schema management"
    Schema is versioned via Alembic migrations. To apply:
    ```bash
    docker compose exec backend alembic upgrade head
    ```
    To inspect live schema:
    ```bash
    docker compose exec postgres psql -U moviefinder -d moviefinder -c "\d+"
    ```
    Or use the `schema-inspector` MCP server for natural-language schema queries.
