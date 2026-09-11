output "theme_name" {
  description = "Theme name, including any environment suffix."
  value       = authsignal_theme.this.name
}

output "flow_versions" {
  description = "Published flow version for each action code."
  value = {
    (authsignal_flow.sign_in.action_code)         = authsignal_flow.sign_in.flow_version
    (authsignal_flow.change_password.action_code) = authsignal_flow.change_password.flow_version
  }
}
