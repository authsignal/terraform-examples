terraform {
  required_version = ">= 1.10"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.6"
    }
  }
}

variable "theme_name" {
  description = "Customer-facing name shown on the hosted screens, already resolved for the environment."
  type        = string
}

variable "primary_color" {
  description = "Brand primary color as a hex value, for example #1F4FD8."
  type        = string
}

variable "logo_url" {
  description = "URL of the brand logo shown on the hosted screens."
  type        = string
  default     = null
}

variable "favicon_url" {
  description = "URL of the brand favicon."
  type        = string
  default     = null
}

variable "watermark_url" {
  description = "URL of the brand watermark, omitted by brands that do not use one."
  type        = string
  default     = null
}

resource "authsignal_theme" "this" {
  name          = var.theme_name
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

resource "authsignal_action_configuration" "classic" {
  action_code                           = "classic"
  default_user_action_result            = "CHALLENGE"
  verification_methods                  = ["PASSKEY", "EMAIL_OTP"]
  default_verification_method           = "PASSKEY"
  prompt_to_enroll_verification_methods = ["PASSKEY"]
}

resource "authsignal_rule" "classic_anonymous_ip" {
  action_code                           = authsignal_action_configuration.classic.action_code
  name                                  = "Anonymous IP"
  description                           = "Step up when the request arrives over a VPN, proxy or Tor exit node."
  priority                              = 0
  type                                  = "CHALLENGE"
  is_active                             = true
  verification_methods                  = ["PASSKEY", "EMAIL_OTP"]
  default_verification_method           = "PASSKEY"
  prompt_to_enroll_verification_methods = ["PASSKEY"]

  conditions = jsonencode({
    and = [{ "==" = [{ "var" = "ip.isAnonymous" }, true] }]
  })
}

resource "authsignal_flow" "sign_in" {
  action_code = "sign-in"

  flow = jsonencode({
    actionNodes = [
      {
        nodeId        = "route-on-risk"
        nodeType      = "RULE"
        parentNodeIds = []
        ruleChildNodeIds = [
          ["anonymous-ip", "block"],
          ["new-device", "verify"],
        ]
        elseChildNodeId = "complete"
      },
      {
        nodeId        = "verify"
        nodeType      = "VERIFICATION"
        parentNodeIds = ["route-on-risk"]
        name          = "Confirm it is you signing in"
        methodConfigurations = {
          PASSKEY   = { isEnabled = true }
          EMAIL_OTP = { isEnabled = true }
        }
        childNodeId = "complete"
      },
      {
        nodeId        = "block"
        nodeType      = "BLOCK"
        parentNodeIds = ["route-on-risk"]
      },
      {
        nodeId        = "complete"
        nodeType      = "COMPLETE"
        parentNodeIds = ["route-on-risk", "verify"]
      },
    ]
    rules = [
      {
        ruleId = "anonymous-ip"
        name   = "Anonymous IP"
        conditions = {
          and = [{ "==" = [{ "var" = "ip.isAnonymous" }, true] }]
        }
      },
      {
        ruleId = "new-device"
        name   = "New device"
        conditions = {
          and = [{ "==" = [{ "var" = "device.isNew" }, true] }]
        }
      },
    ]
  })
}
