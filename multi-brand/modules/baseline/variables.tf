variable "environment" {
  description = "Environment name: dev, test, or prod. Used only as a theme-name suffix."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "display_name" {
  description = "Customer-facing brand name before the environment suffix, from brand.yaml."
  type        = string
}

variable "primary_color" {
  description = "Primary brand colour for hosted screens, as a hex value."
  type        = string
}

variable "logo_url" {
  description = "Logo URL for hosted screens."
  type        = string
}

variable "favicon_url" {
  description = "Favicon URL."
  type        = string
}

variable "watermark_url" {
  description = "Watermark URL, or null to leave unset."
  type        = string
  default     = null
  nullable    = true
}
