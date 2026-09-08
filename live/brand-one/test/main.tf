terraform {
  required_version = ">= 1.10"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.6"
    }
  }

  backend "s3" {}
}

variable "authsignal_host" {
  description = "Management API host for the tenant's region."
  type        = string
  default     = "https://api.authsignal.com/v1/management"
}

variable "tenant_id" {
  description = "Authsignal tenant ID, found under Settings then API keys in the admin portal."
  type        = string
}

variable "environment" {
  description = "One of dev, test, preprod or prod. Used only to name the tenant."
  type        = string

  validation {
    condition     = contains(["dev", "test", "preprod", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, preprod, prod."
  }
}

provider "authsignal" {
  host      = var.authsignal_host
  tenant_id = var.tenant_id
}

locals {
  brand        = yamldecode(file("${path.module}/../brand.yaml"))
  display_name = var.environment == "prod" ? local.brand.display_name : "${local.brand.display_name} (${upper(var.environment)})"
}

module "tenant" {
  source = "../../../modules/authsignal-tenant"

  theme_name    = local.display_name
  primary_color = local.brand.primary_color
  logo_url      = try(local.brand.logo_url, null)
  favicon_url   = try(local.brand.favicon_url, null)
  watermark_url = try(local.brand.watermark_url, null)
}
