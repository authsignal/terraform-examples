# Every tenant is created with a theme. The provider updates a theme but does
# not create one, so this adopts the existing one.
#
# Leaving this in place lets a new tenant onboard with no manual step. Delete
# it after the first apply if you prefer.
# https://developer.hashicorp.com/terraform/language/import
import {
  to = module.authsignal.authsignal_theme.this
  id = "theme"
}
