variable "environment" {
  description = "Environment name: dev, test, or prod. Used only as a theme-name suffix."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}
