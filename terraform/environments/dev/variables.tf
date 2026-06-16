variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "region_abbr" {
  type    = string
  default = "weu"
}

variable "customer" {
  type    = string
  default = "customer"
}

variable "allowed_source_address_prefixes" {
  type        = string
  description = "List of allowed source address prefixes for RDP access to the domain controller. Use CIDR notation (e.g., <IP_ADDRESS>/32)."

}

variable "dc_sku" {
  description = "The SKU for the domain controller virtual machine."
  type        = string
}

variable "dc_admin_username" {
  description = "The username for the domain controller administrator."
  type        = string
}

# Das Admin-Passwort wird von Terraform generiert (random_password) und im
# Key Vault abgelegt -> keine Passwort-Variable mehr.

variable "kv_secret_reader_object_ids" {
  description = "Azure AD object IDs (Users/Gruppen), die das DC-Passwort im Key Vault lesen dürfen (Rolle 'Key Vault Secrets User'). Leer lassen, wenn nur der Deployer Zugriff braucht."
  type        = list(string)
  default     = []
}