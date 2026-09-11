variable "tenant_id" {
  description = "Authsignal tenant ID for this environment, under Settings > API keys in the Authsignal Portal."
  type        = string
}

variable "environment" {
  description = "Environment name: dev, test, or prod. Used only as a theme-name suffix."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "authsignal_host" {
  description = "Management API host for the tenant's region. Override for non-default regions."
  type        = string
  default     = "https://api.authsignal.com/v1/management"
}
