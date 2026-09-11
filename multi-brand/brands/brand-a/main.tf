locals {
  # Optional image keys map to null when omitted from brand.yaml.
  brand = yamldecode(file("${path.module}/brand.yaml"))
}

module "baseline" {
  source = "../../modules/baseline"

  environment = var.environment

  display_name  = local.brand.display_name
  primary_color = local.brand.primary_color
  logo_url      = try(local.brand.logo_url, null)
  favicon_url   = try(local.brand.favicon_url, null)
  watermark_url = try(local.brand.watermark_url, null)
}

# Keep this brand-specific flow outside the shared baseline.
resource "authsignal_flow" "change_password" {
  action_code = "change-password"
  flow        = file("${path.module}/flows/change-password.json")
}
