terraform {
  required_version = ">= 1.10"

  required_providers {
    authsignal = {
      source  = "authsignal/authsignal"
      version = "~> 3.6"
    }
  }

  # The pipeline supplies backend settings and a unique state key, keeping this
  # partial configuration identical across environments.
  backend "azurerm" {}
}
