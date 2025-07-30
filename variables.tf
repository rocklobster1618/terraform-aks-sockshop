
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


