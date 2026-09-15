terraform {
  required_version = ">= 1.11"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.7"
    }
  }
}

locals {
  display_name = var.environment == "prod" ? var.display_name : "${var.display_name} (${upper(var.environment)})"
}

resource "authsignal_theme" "this" {
  name          = local.display_name
  primary_color = var.primary_color

  borders = {
    button_border_radius    = 8
    button_border_width     = 1
    card_border_radius      = 12
    card_border_width       = 1
    input_border_radius     = 8
    input_border_width      = 1
    container_border_radius = 16
  }

  container = {
    content_alignment = "left"
    padding           = 24
    logo_alignment    = "left"
    logo_position     = "inside"
    logo_height       = 32
  }

  links = {
    underline = true
  }

  shadows = {
    enabled = true
  }
}

resource "authsignal_passkey_authenticator_configuration" "passkey" {
  is_active        = true
  relying_party    = "mfa.authsignal.com"
  expected_origins = ["https://mfa.authsignal.com"]
}

resource "authsignal_email_otp_authenticator_configuration" "email_otp" {
  is_active      = true
  email_provider = "SMTP"

  smtp_email_credentials = {
    host     = var.smtp_host
    port     = 465
    secure   = true
    user     = var.smtp_user
    from     = var.smtp_from
    password = var.smtp_password
  }

  smtp_email_credentials_version = var.smtp_credentials_version
}

resource "authsignal_flow" "sign_in" {
  action_code = "sign-in"
  flow        = file("${path.module}/flows/sign-in.json")

  depends_on = [
    authsignal_passkey_authenticator_configuration.passkey,
    authsignal_email_otp_authenticator_configuration.email_otp,
  ]
}
