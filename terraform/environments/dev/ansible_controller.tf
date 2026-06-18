# ─────────────────────────────────────────────────────────────────────────────
# Ansible Control Node (Linux) + self-hosted GitHub Actions Runner (ephemeral).
#
# Liegt in einem EIGENEN, segmentierten Subnet (nicht beim DC) -> begrenzt
# lateral movement. KEINE Public IP: nur Outbound zu GitHub (443); Wartung per
# Azure Serial Console (boot_diagnostics). Registriert sich via cloud-init als
# ephemeral GitHub-Runner und liest den PAT zur Laufzeit per Managed Identity
# aus dem Key Vault (RBAC auf EINZELNES Secret).
# Wiederverwendet aus der DC-Schicht: azurerm_virtual_network.vnet,
# azurerm_resource_group.rg, azurerm_key_vault.kv, time_sleep.kv_rbac_propagation.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  ansible_name_suffix = "ansible-${var.environment}-${var.customer}-${var.region_abbr}"
}

resource "azurerm_resource_group" "ansible" {
  name     = "rg-${local.ansible_name_suffix}"
  location = var.location
}


# SSH-Schluesselpaar (Break-Glass; primaerer Zugang ist die Serial Console).
resource "tls_private_key" "ansible" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "ansible_ssh_private_key" {
  name         = "ansible-controller-ssh-key"
  value        = tls_private_key.ansible.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.kv_rbac_propagation]
}

# ── Eigenes Subnet + NSG fuer den Runner (Segmentierung) ────────────────────
resource "azurerm_network_security_group" "ansible" {
  name                = "nsg-${local.ansible_name_suffix}"
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location

  # Inbound: alles verbieten (der Runner braucht keinen eingehenden Port,
  # auch nicht aus dem VNet -> blockt lateral movement ZUM Runner).
  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound: WinRM (5986) nur zum DC/Session-Host-Subnet.
  security_rule {
    name                       = "Allow-WinRM-To-Hosts"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Outbound: DNS zum DC.
  security_rule {
    name                       = "Allow-DNS-To-DC"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.0/24"
  }

  # Outbound: restlichen Intra-VNet-Verkehr verbieten (kein RDP/SMB zum DC).
  # Internet-Outbound (443 zu GitHub/Azure, apt) bleibt ueber die Default-Regel
  # AllowInternetOutBound erlaubt.
  security_rule {
    name                       = "Deny-Other-VNet-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "ansible" {
  subnet_id                 = azurerm_subnet.ansible.id
  network_security_group_id = azurerm_network_security_group.ansible.id
}

# ── NIC ohne Public IP, im segmentierten Subnet ─────────────────────────────
resource "azurerm_network_interface" "ansible" {
  name                = "nic-${local.ansible_name_suffix}"
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location

  ip_configuration {
    name                          = "ipconfig-${local.ansible_name_suffix}"
    subnet_id                     = azurerm_subnet.ansible.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
  }
}

resource "azurerm_linux_virtual_machine" "ansible" {
  name                = "vm-${local.ansible_name_suffix}"
  resource_group_name = azurerm_resource_group.ansible.name
  location            = azurerm_resource_group.ansible.location
  size                = var.ansible_vm_size
  admin_username      = var.ansible_admin_username
  network_interface_ids = [
    azurerm_network_interface.ansible.id,
  ]

  admin_ssh_key {
    username   = var.ansible_admin_username
    public_key = tls_private_key.ansible.public_key_openssh
  }

  # System-Managed-Identity -> liest NUR github-runner-pat aus dem Key Vault.
  identity {
    type = "SystemAssigned"
  }

  # Serial Console (Break-Glass ohne Inbound-Port) braucht Boot Diagnostics.
  boot_diagnostics {}

  custom_data = base64encode(templatefile("${path.module}/cloud-init/ansible-controller.yaml", {
    kv_name       = azurerm_key_vault.kv.name
    repo_url      = var.github_repo_url
    runner_labels = var.runner_labels
    admin_user    = var.ansible_admin_username
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# ── least-privilege: MI darf NUR das eine Secret lesen ──────────────────────
resource "azurerm_role_assignment" "ansible_kv_reader" {
  scope                = "${azurerm_key_vault.kv.id}/secrets/github-runner-pat"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.ansible.identity[0].principal_id
}

# ── azure_rm Dynamic Inventory: MI darf die RG read-only enumerieren ────────
resource "azurerm_role_assignment" "ansible_rg_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_linux_virtual_machine.ansible.identity[0].principal_id
}
