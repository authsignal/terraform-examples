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

variable "smtp_host" {
  description = "SMTP host that delivers Email OTP messages."
  type        = string
}

variable "smtp_user" {
  description = "SMTP username."
  type        = string
}

variable "smtp_from" {
  description = "Address Email OTP messages are sent from."
  type        = string
}

variable "smtp_password" {
  description = "SMTP password for Email OTP. Supply it as TF_VAR_smtp_password; it is never written to state."
  type        = string
  ephemeral   = true
  sensitive   = true
}

variable "smtp_credentials_version" {
  description = "Rotation marker for the SMTP credentials. Change it to resend them. Never a secret."
  type        = string
}
