# Everything this module manages is the same in every tenant, apart from the
# three variables above.

resource "authsignal_theme" "this" {
  name          = var.tenant_display_name
  primary_color = "#4F46E5"
}

resource "authsignal_passkey_authenticator_configuration" "passkey" {
  is_active        = true
  relying_party    = var.passkey_relying_party
  expected_origins = var.passkey_expected_origins
}

resource "authsignal_flow" "sign_in" {
  action_code = "sign-in"
  flow        = file("${path.module}/flows/sign-in.json")

  # The flow offers passkey, so the authenticator has to exist first.
  depends_on = [authsignal_passkey_authenticator_configuration.passkey]
}
