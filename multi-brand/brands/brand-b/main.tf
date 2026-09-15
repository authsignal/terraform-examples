locals {
  brand = yamldecode(file("${path.module}/brand.yaml"))
}

module "baseline" {
  source = "../../modules/baseline"

  environment = var.environment

  display_name  = local.brand.display_name
  primary_color = local.brand.primary_color

  smtp_host                = var.smtp_host
  smtp_user                = var.smtp_user
  smtp_from                = var.smtp_from
  smtp_password            = var.smtp_password
  smtp_credentials_version = var.smtp_credentials_version
}

resource "authsignal_flow" "add_payment_method" {
  action_code = "add-payment-method"
  flow        = file("${path.module}/flows/add-payment-method.json")

  depends_on = [module.baseline]
}
