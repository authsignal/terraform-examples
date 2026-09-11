output "theme_name" {
  description = "Theme name, including any environment suffix."
  value       = module.baseline.theme_name
}

output "flow_versions" {
  description = "Published flow versions for the baseline and Brand B."
  value = merge(module.baseline.flow_versions, {
    (authsignal_flow.add_payment_method.action_code) = authsignal_flow.add_payment_method.flow_version
  })
}
