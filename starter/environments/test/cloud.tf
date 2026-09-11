terraform {
  cloud {
    organization = "example-org"

    workspaces {
      name = "authsignal-test"
    }
  }
}
