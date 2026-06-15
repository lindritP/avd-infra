terraform {
  backend "azurerm" {
    resource_group_name  = "rg-avd-tfstate-weu-001"
    storage_account_name = "stavdtfstate3794ea" # <-- dein SA_STATE
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true
  }
}