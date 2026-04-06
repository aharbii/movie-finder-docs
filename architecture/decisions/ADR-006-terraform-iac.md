# ADR-006: Terraform Infrastructure as Code — Azure Primary, Multi-Cloud Extensible

**Date:** 2026-04-06
**Status:** Accepted

---

## Context

Infrastructure provisioning was previously done through ad-hoc `az` CLI scripts and
one-time manual steps with no version-controlled state. This caused several problems:

1. **No idempotency**: re-running a script in a different order or against a partially
   provisioned environment could leave resources in an inconsistent state.
2. **No drift detection**: resources created manually were not tracked anywhere, so changes
   made outside the script (e.g., via the Azure portal) were invisible to the team.
3. **No multi-environment support**: there was no clean way to maintain separate staging and
   production environments with different resource sizes but identical topology.
4. **No multi-cloud path**: if the team ever needed to run on AWS or GCP, there was no
   abstraction layer — every resource would need to be re-created from scratch.
5. **Secrets not lifecycle-managed**: the `provision.sh` script baked secrets directly into
   container app environment variables rather than using Key Vault references.

---

## Decision

### 1. Terraform as the IaC tool

Terraform is adopted in the `infrastructure/` submodule. It is the primary tool for all
Azure resource provisioning. HashiCorp Configuration Language (HCL) is human-readable,
well-documented, and has first-class Azure support via `hashicorp/azurerm ~> 4.0`.

### 2. Remote state on Azure Storage Account

Terraform state is stored in an Azure Storage Account (`moviefindertfstate`), in a container
named `tfstate`, with the key `movie-finder.tfstate`. The storage account is bootstrapped
once via `scripts/bootstrap-state.sh` and is never managed by Terraform itself.

State locking is provided by Azure Blob lease semantics — no separate DynamoDB table required.

### 3. Module structure

The Terraform workspace is organized into reusable modules:

| Module               | Resources provisioned                                            |
| -------------------- | ---------------------------------------------------------------- |
| `networking`         | VNet, subnets with delegations, private DNS zone, VNet link      |
| `container_registry` | Azure Container Registry                                         |
| `key_vault`          | Azure Key Vault with managed secrets (`lifecycle ignore_changes`) |
| `database`           | PostgreSQL Flexible Server (HA in production)                    |
| `container_apps`     | Container Apps Environment, managed identity, backend + frontend |

### 4. Multi-cloud extensibility via toggle variables

AWS (`aws ~> 5.0`) and GCP (`google ~> 6.0`) providers are declared but disabled by default
via `enable_aws = false` and `enable_gcp = false` input variables. When toggled, the
providers activate and corresponding modules can be wired in without touching the Azure path.

### 5. Image updates bypass Terraform

Container App image references use `lifecycle { ignore_changes = [image] }`. Images are
updated by the CI/CD pipeline (`az containerapp update`), not by Terraform. This prevents
Terraform plan/apply cycles from reverting pipeline-deployed images back to the
`variables.tf` default.

### 6. Secrets rotate via Key Vault, not Terraform

Key Vault secrets use `lifecycle { ignore_changes = [value] }`. Initial secret values are
set by Terraform on first `apply`. Subsequent rotations happen via the Azure Key Vault API
or portal. Terraform never overwrites a rotated secret.

---

## Consequences

**Positive:**
- Reproducible infrastructure: `terraform apply` from a clean state produces an identical
  environment every time.
- Environment parity: staging and production are identical except for size variables
  (`acr_sku`, `db_storage_mb`, `min_replicas`).
- Secrets managed safely: Key Vault reference injection means secrets never appear in
  container app environment variable values in plain text.
- Multi-cloud path is available with low adoption cost.

**Negative:**
- Terraform state file is sensitive: compromise of the state storage account or state file
  exposes resource IDs, connection strings, and managed identity details.
- First `apply` on a new subscription requires bootstrapping the state backend manually
  (`scripts/bootstrap-state.sh`).
- Terraform `destroy` on a production environment requires overriding `prevent_destroy = true`
  on the database module — this is intentional but adds friction for catastrophic rollbacks.

---

## Future considerations

- Add `terraform plan` as a GitHub Actions check on PRs targeting `main` in the
  `infrastructure` repo.
- Introduce a staging Qdrant collection (see ADR-001 open item) to isolate vector data
  between environments.
- Evaluate Terragrunt for managing multiple environment configurations when the number of
  environments grows beyond staging + production.
