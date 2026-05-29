locals {
  name_suffix = "${var.workload}-${var.environment}-${var.region_abbr}"
  tags = {
    workload    = var.workload
    environment = var.environment
    managedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "workload" {
  name     = "rg-${local.name_suffix}-001"
  location = var.location
  tags     = local.tags
}

output "resource_group_name" {
  value = azurerm_resource_group.workload.name
}