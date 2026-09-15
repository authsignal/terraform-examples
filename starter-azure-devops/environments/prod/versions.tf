terraform {
  required_version = ">= 1.11"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.7"
    }
  }

  backend "azurerm" {}
}
