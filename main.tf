


# Create ResourceGroups based on what's specified in variables.tf
resource "azurerm_resource_group" "groups" {
    location = var.location
    name     = "${var.prefix}-${each.value}-rg"
    for_each = toset(var.groups)
}