terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.0"
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


