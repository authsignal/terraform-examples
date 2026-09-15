provider "authsignal" {
  host      = var.authsignal_host
  tenant_id = var.tenant_id
}

module "tenant" {
  source = "../../modules/authsignal-tenant"

  environment = var.environment

  smtp_host                = var.smtp_host
  smtp_user                = var.smtp_user
  smtp_from                = var.smtp_from
  smtp_password            = var.smtp_password
  smtp_credentials_version = var.smtp_credentials_version
}

import {
  to = module.tenant.authsignal_theme.this
  id = var.tenant_id
}

output "theme_name" {
  description = "Theme name, including any environment suffix."
  value       = module.tenant.theme_name
}

output "flow_versions" {
  description = "Published flow version for each action code."
  value       = module.tenant.flow_versions
}
