# The provider reads AUTHSIGNAL_HOST, AUTHSIGNAL_TENANT_ID and
# AUTHSIGNAL_API_SECRET. Set them as workspace variables in HCP Terraform.
provider "authsignal" {}

module "authsignal" {
  source = "../../../modules/authsignal"

  tenant_display_name      = var.tenant_display_name
  passkey_relying_party    = var.passkey_relying_party
  passkey_expected_origins = var.passkey_expected_origins
}
