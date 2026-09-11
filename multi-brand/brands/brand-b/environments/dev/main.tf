# All six roots are identical because each brand module is the root's
# grandparent. Environment-specific values arrive through variables.

provider "authsignal" {
  host      = var.authsignal_host
  tenant_id = var.tenant_id

  # Read api_secret from AUTHSIGNAL_API_SECRET so it is not stored here.
}

module "brand" {
  source = "../.."

  environment = var.environment
}

# Each tenant already has one theme, and the provider cannot create it. Keep this
# block permanently so Terraform adopts the theme before managing it.
# var.tenant_id supplies the required non-empty import ID; the provider addresses
# the tenant's only theme without using this value to select a resource.
import {
  to = module.brand.module.baseline.authsignal_theme.this
  id = var.tenant_id
}

output "theme_name" {
  description = "Theme name, including any environment suffix."
  value       = module.brand.theme_name
}

output "flow_versions" {
  description = "Published flow version for each action code."
  value       = module.brand.flow_versions
}
