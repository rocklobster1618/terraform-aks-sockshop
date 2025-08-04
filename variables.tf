
variable "subid"{
    default     = "cdb51940-ec76-49d0-a6cf-a0984b845428"
    type        = string
    description = "the subscription to deploy this configuration to"
}

variable "prefix" {
    default     = "DEMO72"
    type        = string
    description = "naming prefix for all resources"
}

variable "location" {
    default = "eastus"
    type = string
    description = "azure region to deploy all azure resources to"
}

variable "my_ip"{
    default = ""        # If blank will pull public IP dynamically
    type = string
    description = "my own public IP address to be whitelisted for accessing the AKS cluster cmd-line"
}

variable "my_ip"{
    default = ""        # If blank will pull public IP dynamically
    type = string
    description = "my own public IP address to be whitelisted for accessing the AKS cluster cmd-line"
}

variable "vnet_range"{
    default = "10.0.0.0/16"
    type = string
    description = "address range to use for the Vnet"
}

variable "subnet_range"{
    default = "10.0.1.0/24"
    type = string
    description = "address range to use for the single subnet the AKS cluster will be deployed to. Must exist within Vnet range"
}
