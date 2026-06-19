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
  type        = list(string)
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

# ── Ansible Control Node / self-hosted GitHub Runner ────────────────────────

# variable "ansible_vm_size" {
#   description = "VM-Groesse der Ansible-Control-Node / des self-hosted Runners."
#   type        = string
#   default     = "Standard_B2s"
# }

# variable "ansible_admin_username" {
#   description = "Lokaler Admin-/SSH-Benutzer der Ansible-Control-Node."
#   type        = string
#   default     = "azureadmin"
# }

# variable "github_repo_url" {
#   description = "GitHub-Repo-URL, bei dem sich der self-hosted Runner registriert."
#   type        = string
#   default     = "https://github.com/lindritP/avd-infra"
# }

# variable "runner_labels" {
#   description = "Labels des self-hosted GitHub-Runners (kommagetrennt)."
#   type        = string
#   default     = "self-hosted,vnet"
# }