variable "tenant_display_name" {
  description = "The name shown to users in the pre-built UI."
  type        = string
}

variable "passkey_relying_party" {
  description = "The domain passkeys are scoped to, with no URL scheme."
  type        = string
}

variable "passkey_expected_origins" {
  description = "Origins allowed to use passkeys. Each begins with https://."
  type        = set(string)
}
