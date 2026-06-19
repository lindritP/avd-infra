environment = "dev"
# workload / location / region_abbr nutzen die Defaults

customer = "lindrit"

allowed_source_address_prefixes = ["91.112.213.242/32", "46.125.106.192/32"]

dc_sku            = "Standard_B2ls_v2"
dc_admin_username = "lindadmin"
# dc_admin_password entfällt – wird von Terraform generiert und im Key Vault abgelegt.

# Optional: eigene Azure-AD-Object-ID(s), um das DC-Passwort im Key Vault lesen zu dürfen.
# kv_secret_reader_object_ids = ["<deine-object-id>"]

ansible_vm_size = "Standard_B2ls_v2"