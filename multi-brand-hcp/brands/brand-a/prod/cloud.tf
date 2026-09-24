terraform {
  required_version = ">= 1.10"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.10"
    }
  }

  cloud {
    organization = "your-org"

    workspaces {
      name    = "brand-a-prod"
      project = "brand-a"
    }
  }
}
