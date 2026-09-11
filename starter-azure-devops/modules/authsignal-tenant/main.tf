terraform {
  required_version = ">= 1.10"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.6"
    }
  }
}

locals {
  company_display_name = "Example Co"

  # Identify non-production tenants in screenshots with a visible suffix.
  display_name = var.environment == "prod" ? local.company_display_name : "${local.company_display_name} (${upper(var.environment)})"
}

resource "authsignal_theme" "this" {
  name          = local.display_name
  primary_color = var.primary_color
  logo_url      = var.logo_url
  favicon_url   = var.favicon_url
  watermark_url = var.watermark_url

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

resource "authsignal_flow" "sign_in" {
  action_code = "sign-in"
  flow        = file("${path.module}/flows/sign-in.json")
}

resource "authsignal_flow" "change_password" {
  action_code = "change-password"
  flow        = file("${path.module}/flows/change-password.json")
}
