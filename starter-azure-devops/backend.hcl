# The pipeline supplies a unique key per environment. Defining one here would
# make every root share the same state file.

resource_group_name  = "rg-authsignal-tfstate"
storage_account_name = "stauthsignaltfstate"
container_name       = "tfstate"
use_azuread_auth = true
