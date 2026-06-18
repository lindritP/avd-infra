locals {
  name_suffix = "dc-${var.environment}-${var.customer}-${var.region_abbr}"

  dc_ip_address = "10.0.1.4"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}

resource "azurerm_network_interface" "domain_controller_nic" {
  name                = "nic-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "ipconfig-${local.name_suffix}"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.dc_ip_address
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.name_suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "Allow-RDP-Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_source_address_prefixes
    destination_address_prefix = "*"
  }

  # Hinweis: Die fruehere "Allow-SSH-Inbound"-Regel (Port 22 aus dem Internet)
  # wurde entfernt. Der Ansible-Controller hat keine Public IP mehr und liegt im
  # eigenen Subnet; der DC ist Windows und wird per WinRM/RDP verwaltet.
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "domain_controller" {
  name                = "dc-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.dc_sku
  admin_username      = var.dc_admin_username
  admin_password      = random_password.dc.result
  network_interface_ids = [
    azurerm_network_interface.domain_controller_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }

  # Tags -> vom azure_rm Dynamic Inventory zur Gruppierung genutzt.
  tags = {
    role        = "dc"
    environment = var.environment
    os          = "windows"
  }
}