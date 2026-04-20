---
title: Context & Deployment Diagrams
description: System context overview and Azure production deployment topology for Movie Finder.
---

# Context & Deployment

High-level system boundary views showing all runtime components, external dependencies, and the Azure production deployment topology.

---

## 01 — System Context

All runtime components, external services, provider integrations (ADR-0008), and CI/CD pipeline in one view. Annotations mark open issues visible at the system boundary.

![System Context](01-system-context.png)

---

## 02 — Azure Production Deployment

Container Apps environment, PostgreSQL Flexible Server, ACR, Key Vault, Qdrant Cloud, Jenkins CI/CD, and local docker compose reference.

![Azure Deployment](02-deployment-azure.png)
