output "resource_group_name" {
  description = "Name der Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Region der Resource Group"
  value       = azurerm_resource_group.rg.location
}

output "vnet_name" {
  description = "Name des Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "ID des Virtual Network (z.B. fuer VNet-Peering)"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  description = "ID des Subnets"
  value       = azurerm_subnet.subnet.id
}

output "dc_private_ip_address" {
  description = "Private IP-Adresse des Domain Controllers (gleichzeitig DNS-Server des VNet)"
  value       = azurerm_network_interface.domain_controller_nic.private_ip_address
}

output "dc_vm_name" {
  description = "Name der Domain-Controller-VM"
  value       = azurerm_windows_virtual_machine.domain_controller.name
}

output "dc_vm_id" {
  description = "Resource-ID der Domain-Controller-VM"
  value       = azurerm_windows_virtual_machine.domain_controller.id
}

output "dc_admin_username" {
  description = "Admin-Benutzername des Domain Controllers"
  value       = azurerm_windows_virtual_machine.domain_controller.admin_username
}

output "nsg_id" {
  description = "ID der Network Security Group"
  value       = azurerm_network_security_group.nsg.id
}

output "key_vault_name" {
  description = "Name des Key Vault, der das DC-Admin-Passwort enthält"
  value       = azurerm_key_vault.kv.name
}

output "dc_admin_password_secret_id" {
  description = "Key-Vault-Secret-ID des DC-Admin-Passworts (NICHT der Wert; abrufbar via 'az keyvault secret show')"
  value       = azurerm_key_vault_secret.dc_admin_password.id
}

output "ansible_controller_private_ip" {
  description = "Private IP der Ansible-Control-Node im segmentierten Subnet"
  value       = azurerm_network_interface.ansible.private_ip_address
}

# output "ansible_controller_access_hint" {
#   description = "Wartungszugang ohne Public IP: Azure Serial Console (Portal -> VM -> Serial Console) oder Bastion/JIT. Break-Glass-SSH-Key liegt im Key Vault (Secret ansible-controller-ssh-key)."
#   value       = "Portal -> vm-${local.ansible_name_suffix} -> Serial Console"
# }
