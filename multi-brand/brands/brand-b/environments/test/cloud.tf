terraform {
  cloud {
    organization = "example-org"

    workspaces {
      name = "authsignal-brand-b-test"
    }
  }
}
