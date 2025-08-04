## Azure Kubernetes Service (AKS) Cluster Deployment via Terraform

This project provisions a complete AKS (Azure Kubernetes Service) cluster using Terraform.
It sets up all foundational Azure infrastructure necessary to host containerized workloads, with production-adjacent features like monitoring, identity integration, and secret management.

---

## Architecture Overview

**Provisioned Resources:**
- Azure Resource Group
- Virtual Network + Subnet
- AKS Cluster (User-Assigned Managed Identity)
- Azure Container Registry (ACR)
- Azure Key Vault (for secret management)
- Azure Log Analytics Workspace
- Diagnostic Settings for monitoring
- AzureAD Group integration for RBAC
- Public SSH key generation
- IP whitelisting for API server access

---

## GETTING STARTED

### Prerequisites
- [Terraform v1.5+](https://developer.hashicorp.com/terraform/downloads)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- See 'prerequisites.txt' for how to login to azure and prep subscription before running terraform

### K8s Authentication
- See 'kubectl.txt' for how to connect to this AKS cluster interactively post-provisioning in