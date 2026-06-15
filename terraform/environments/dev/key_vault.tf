# ─────────────────────────────────────────────────────────────────────────────
# Key Vault für das DC-Admin-Passwort.
# Muster: Terraform generiert das Passwort (random_password) -> legt es als
# Secret im Key Vault ab -> die VM referenziert random_password.dc.result.
# Niemand tippt oder committet das Passwort; zum RDP-Login holt man es aus dem KV.
# Zugriff über RBAC (Azure-Empfehlung), NICHT über Legacy Access Policies.
# ─────────────────────────────────────────────────────────────────────────────

# Identität, die Terraform ausführt: lokal dein User, in der Pipeline der OIDC-SP.
data "azurerm_client_config" "current" {}

# Vom Provisioning generiertes Admin-Passwort.
# override_special: nur Windows-freundliche Sonderzeichen.
resource "random_password" "dc" {
  length           = 24
  special          = true
  override_special = "!#$%*()-_=+[]"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-${local.name_suffix}" # global eindeutig; bei Kollision Suffix anhängen
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # RBAC statt Access Policies (Best Practice / Azure-Empfehlung).
  rbac_authorization_enabled = true

  # dev: volles Löschen im Test möglich. Für prod auf true setzen.
  purge_protection_enabled = false
}

# Der Deployer (ausführende Identität) darf Secrets schreiben/lesen.
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC-Rollenzuweisungen propagieren verzögert -> sonst 403 beim ersten Secret-Write.
resource "time_sleep" "kv_rbac_propagation" {
  depends_on      = [azurerm_role_assignment.deployer_secrets_officer]
  create_duration = "60s"
}

# Optionale Lese-Berechtigung für menschliche Accounts (z.B. dein Azure-AD-User),
# damit du das Passwort im Portal/CLI fürs RDP abholen kannst. In der Pipeline ist
# der Deployer ein SP, nicht dein User -> hier deine Object-ID(s) eintragen.
resource "azurerm_role_assignment" "secret_readers" {
  for_each             = toset(var.kv_secret_reader_object_ids)
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "azurerm_key_vault_secret" "dc_admin_password" {
  name         = "dc-admin-password"
  value        = random_password.dc.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.kv_rbac_propagation]
}
