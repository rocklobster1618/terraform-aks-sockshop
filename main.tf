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

# Create ResourceGroups based on what's specified in variables.tf
resource "azurerm_resource_group" "aks-rg" {
    location = var.location
    name     = "${var.prefix}-AKS-rg"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
    name                = "AKS-VN1"
    location            = var.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    address_space       = ["10.0.0.0/16"]

    tags = {
        environment = "Production"
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


# KeyVault
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "kv" {
    name                        = "AKS-kv"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.aks-rg.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    soft_delete_retention_days  = 7
    purge_protection_enabled    = false
    enable_rbac_authorization   = true
    sku_name                    = "standard"
}


# Azure Container Registry
resource "azurerm_container_registry" "acr" {
    name                = "containerRegistry1"
    resource_group_name = azurerm_resource_group.aks-rg.name
    location            = var.location
    sku                 = "Basic"
    admin_enabled       = true
}


# Managed Identity
resource "azurerm_user_assigned_identity" "cluster-mi" {
    location            = var.location
    name                = "example"
    resource_group_name = azurerm_resource_group.aks-rg.name
}

# Assign Roles to Managed Identity
resource "azurerm_role_assignment" "example" {
    principal_id         = azurerm_user_assigned_identity.cluster-mi.principal_id
    scope                = azurerm_key_vault.kv.id
    role_definition_name = "Key Vault Administrator"
}
resource "azurerm_role_assignment" "example" {
    principal_id         = azurerm_user_assigned_identity.cluster-mi.principal_id
    scope                = azurerm_container_registry.acr.id
    role_definition_name = "AcrPull"
}

# Create EntraID group for ClusterAdmins
data "azuread_client_config" "current" {}
resource "azuread_group" "aks_admins" {
    display_name     = "AKS Admins"
    owners           = [data.azuread_client_config.current.object_id]
    security_enabled = true
}


# AKS Cluster
resource "azurerm_kubernetes_cluster" "example" {
    name                = "Cluster1-aks"
    location            = var.location
    resource_group_name = azurerm_resource_group.aks-rg.name
    dns_prefix          = "exampleaks1"
    kubernetes_version  = "1.32.5"
    role_based_access_control_enabled = true

    default_node_pool {
        name       = "default"
        node_count = 2
        vm_size    = "Standard_B2ms"
    }

    identity {
        type = "UserAssigned"
        identity_ids = azurerm_user_assigned_identity.cluster-mi.id
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
        admin_username = "ozymandias"

        ssh_key {
            key_data = tls_private_key.ssh_key.public_key_openssh
        }
    }

    network_profile {
        network_plugin      = "azure"
        dns_service_ip      = "10.240.0.10"
        service_cidr        = "10.240.0.0/16"
        docker_bridge_cidr  = "172.17.0.1/16"
        network_policy      = "calico"
        outbound_type       = "loadBalancer"
        load_balancer_sku   = "standard"
    }


    tags = {
        Environment = "Production"
    }
}