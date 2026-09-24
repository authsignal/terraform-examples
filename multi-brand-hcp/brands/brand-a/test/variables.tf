variable "tenant_display_name" {
  type = string
}

variable "passkey_relying_party" {
  type = string
}

variable "passkey_expected_origins" {
  type = set(string)
}
