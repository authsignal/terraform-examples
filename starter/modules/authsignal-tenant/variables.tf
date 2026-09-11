variable "environment" {
  description = "Environment name: dev, test, or prod. Used only as a theme-name suffix."
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "primary_color" {
  description = "Primary brand colour for hosted screens, as a hex value."
  type        = string
  default     = "#1F4FD8"
}

variable "logo_url" {
  description = "Logo URL for hosted screens."
  type        = string
  default     = "https://cdn.example.com/logo.svg"
}

variable "favicon_url" {
  description = "Favicon URL."
  type        = string
  default     = "https://cdn.example.com/favicon.png"
}

variable "watermark_url" {
  description = "Watermark URL, or null to leave unset."
  type        = string
  default     = "https://cdn.example.com/watermark.svg"
}
