variable "resource_providers" {
    default = [
        "Microsoft.ApiManagement",
        "Microsoft.AVS",
        "Microsoft.DBforPostgreSQL"
    ]
    description = "set of providers to register in azure subscription by default. don't change unless you know what you're doing"
}
variable "subid"{
    default     = "b5b97ba6-d17f-4a21-8d05-2a2fa1359c6e"
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


variable "groups" {
    default     = ["AD","RDS","SQL","VNET"]
    type        = list(string)
    description = "standard resource groups to make"
}