locals {
  name_suffix = "${var.workload}-${var.environment}-${var.region_abbr}"
  tags = {
    workload    = var.workload
    environment = var.environment
    managedBy   = "terraform"
  }

  skuName = "RS0"

  skuTier = "Standard"
}

resource "azurerm_resource_group" "workload" {
  name     = "rg-${local.name_suffix}-001"
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-storage"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "storage" {
  name                     = "stavdbackup${var.region_abbr}${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_share" "fileshare" {
  name                 = "generealfileshare"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 1
  depends_on           = [azurerm_storage_account.storage]
}


resource "azurerm_resource_group" "rg-backup" {
  name     = "rg-backup001"
  location = var.location
  tags     = local.tags
}

# Create Recovery Services Vault
resource "azurerm_recovery_services_vault" "vault" {
  name                = var.vaultName
  location            = azurerm_resource_group.rg-backup.location
  resource_group_name = azurerm_resource_group.rg-backup.name
  sku                 = local.skuName
}


# Register the storage account with the Recovery Services Vault
resource "azurerm_backup_container_storage_account" "container" {
  resource_group_name = azurerm_resource_group.rg-backup.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  storage_account_id  = azurerm_storage_account.storage.id
}
resource "azurerm_backup_protected_file_share" "share1" {
  resource_group_name = azurerm_resource_group.rg-backup.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_file_share_name  = azurerm_storage_share.fileshare.name
  backup_policy_id    = azurerm_backup_policy_file_share.policy.id
  source_storage_account_id = azurerm_backup_container_storage_account.container.storage_account_id
}

# Create Backup Policy for File Share
resource "azurerm_backup_policy_file_share" "policy" {
  name                = "vaultstorageconfig"
  resource_group_name = azurerm_resource_group.rg-backup.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.workload.name
}