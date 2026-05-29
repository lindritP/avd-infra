terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Auth lokal: deine az-CLI-Session. In der Pipeline: OIDC via ARM_*-Env.
  # subscription_id liest der Provider aus ARM_SUBSCRIPTION_ID.
}