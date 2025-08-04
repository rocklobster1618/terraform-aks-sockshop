terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.0"
        }
        azuread = {
            source = "hashicorp/azuread"
            version = "~>3.4.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~>3.0"
        }
        null = {
            source = "hashicorp/null"
            version = "~>3.2.0"
        }
    }
}

provider "azurerm" {
    features {
        key_vault {
            purge_soft_delete_on_destroy    = true
            recover_soft_deleted_key_vaults = true
        }
    }

    subscription_id = var.subid
}

provider "azuread" {
    tenant_id = data.azurerm_client_config.current.tenant_id
}

/*

THIS SECTION WILL BE MOVED INTO ARGOCD PROJECT AT SOME POINT


# Authenticate to Kubernetes Cluster (to deploy K8s Resources)
data "azurerm_kubernetes_cluster" "aks" {
    name                = "my-aks-cluster"
    resource_group_name = "my-rg"
}
provider "kubernetes" {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}
*/