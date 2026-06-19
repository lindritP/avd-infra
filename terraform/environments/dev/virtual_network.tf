locals {
  vnet_name_suffix = "vnet-${var.environment}-${var.customer}-${var.region_abbr}"
}

resource "azurerm_resource_group" "rg-vnet" {
  name     = "rg-${local.vnet_name_suffix}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name_suffix
  resource_group_name = azurerm_resource_group.rg-vnet.name
  location            = azurerm_resource_group.rg-vnet.location
  address_space       = ["10.0.0.0/16"]
  //dns_servers         = [local.dc_ip_address]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${local.name_suffix}"
  resource_group_name  = azurerm_resource_group.rg-vnet.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# resource "azurerm_subnet" "ansible" {
#   name                 = "snet-${local.ansible_name_suffix}"
#   resource_group_name  = azurerm_resource_group.rg-vnet.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.2.0/24"]
# }
