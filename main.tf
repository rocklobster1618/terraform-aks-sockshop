# Generate SSH Key 
resource "tls_private_key" "ssh_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

# Save SSH key locally
resource "local_file" "private_key" {
    content  = tls_private_key.ssh_key.private_key_pem
    filename = "${path.module}/id_rsa"
}
resource "local_file" "public_key" {
    content  = tls_private_key.ssh_key.public_key_openssh
    filename = "${path.module}/id_rsa.pub"
}

# Resource Group to contain all Azure Resources
resource "azurerm_resource_group" "aks-rg" {
    location = var.location
    name     = "${var.prefix}-AKS-rg"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.prefix}-AKS-VN1"
    location            = var.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    address_space       = ["10.0.0.0/16"]

    tags = {
        LifeCyle = "Production"
    }
}

# Subnet
resource "azurerm_subnet" "subnet" {
    name                 = "${azurerm_virtual_network.vnet.name}-sbnt1"
    resource_group_name  = azurerm_resource_group.aks-rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
    service_endpoints   = ["Microsoft.AzureActiveDirectory","Microsoft.ContainerRegistry","Microsoft.KeyVault","Microsoft.Storage"]

    delegation {
        name = "askDelegation"
        service_delegation {
            name    = "Microsoft.ContainerService/managedClusters"
        }
    }
}


# KeyVault (for Kubernetes secret storage/management)
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv" {
    name                        = "${var.prefix}-AKS-kv"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.aks-rg.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false
    enable_rbac_authorization   = true
    sku_name                    = "standard"
}


# Azure Container Registry (for image control, instead of pulling directly from docker.io)
resource "azurerm_container_registry" "acr" {
    name                = "${var.prefix}acr"
    resource_group_name = azurerm_resource_group.aks-rg.name
    location            = var.location
    sku                 = "Basic"
    admin_enabled       = true
}


# Managed Identity (for AKS cluster and can define roles/permissions ahead of time)
resource "azurerm_user_assigned_identity" "cluster-mi" {
    location            = var.location
    name                = "${var.prefix}-AKS-mi"
    resource_group_name = azurerm_resource_group.aks-rg.name
}

# Assign Roles to Managed Identity
resource "azurerm_role_assignment" "kv" {
    principal_id         = azurerm_user_assigned_identity.cluster-mi.principal_id
    scope                = azurerm_key_vault.kv.id
    role_definition_name = "Key Vault Administrator"
}
resource "azurerm_role_assignment" "acr" {
    principal_id         = azurerm_user_assigned_identity.cluster-mi.principal_id
    scope                = azurerm_container_registry.acr.id
    role_definition_name = "AcrPull"
}
resource "azurerm_role_assignment" "law" {
    principal_id         = azurerm_user_assigned_identity.cluster-mi.principal_id
    role_definition_name = "Monitoring Metrics Publisher"
    scope                = azurerm_log_analytics_workspace.aks_logs.id
}

# Create EntraID group for ClusterAdmins (members of this group will receive Admin role for the cluster)
data "azuread_client_config" "current" {}
resource "azuread_group" "aks_admins" {
    display_name     = "AKS Admins"
    owners           = [data.azuread_client_config.current.object_id]
    security_enabled = true
}


# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
    name                = "${var.prefix}-cluster"
    location            = var.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    dns_prefix          = "exampleaks1"                               ###############
    kubernetes_version  = "1.32.5"
    role_based_access_control_enabled = true

    default_node_pool {
        name       = "default"
        node_count = 2
        vm_size    = "Standard_B2ms"
    }

    identity {
        type = "UserAssigned"
        identity_ids = ["${azurerm_user_assigned_identity.cluster-mi.id}"]
    }

    azure_active_directory_role_based_access_control {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        admin_group_object_ids  = ["${azuread_group.aks_admins.object_id}"]
        azure_rbac_enabled      = false
    }

    api_server_access_profile {
        authorized_ip_ranges = ["69.142.215.134/32"]
    }
    
    key_vault_secrets_provider {
        secret_rotation_enabled = true
    }

    linux_profile {
        admin_username = "barfoo"

        ssh_key {
            key_data = tls_private_key.ssh_key.public_key_openssh
        }
    }

    network_profile {
        network_plugin      = "azure"
        dns_service_ip      = "10.240.0.10"
        service_cidr        = "10.240.0.0/16"
        # docker_bridge_cidr  = "172.17.0.1/16"  # Appears to be deprecated? Leaving it, just in case
        network_policy      = "calico"
        outbound_type       = "loadBalancer"
        load_balancer_sku   = "standard"
    }

    oms_agent {
        log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
        msi_auth_for_monitoring_enabled = true
    }

    tags = {
        LifeCycle = "Production"
    }
}

# Log Analytics Workspace (stores all azure-level metrics/logs from cluster)
resource "azurerm_log_analytics_workspace" "aks_logs" {
    name                = "${var.prefix}-law"
    location            = var.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    sku                 = "PerGB2018"
    retention_in_days   = 30
}

# Cluster Metrics (configures azure monitor to collect metrics/logs specified below)
resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
    name                       = "${azurerm_kubernetes_cluster.aks.name}-diag"
    target_resource_id         = azurerm_kubernetes_cluster.aks.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id

    enabled_log {
        category = "kube-apiserver"
    }

    enabled_log {
        category = "kube-controller-manager"
    }

    enabled_log {
        category = "kube-scheduler"
    }

    enabled_log {
        category = "cluster-autoscaler"
    }

    enabled_metric {
        category = "AllMetrics"
    }
}