output "theme_name" {
  description = "Theme name, including any environment suffix."
  value       = module.baseline.theme_name
}

output "flow_versions" {
  description = "Published flow versions for the baseline and Brand A."
  value = merge(module.baseline.flow_versions, {
    (authsignal_flow.change_password.action_code) = authsignal_flow.change_password.flow_version
  })
}
