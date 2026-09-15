# Authsignal Terraform examples

Examples for managing Authsignal tenant configuration with Terraform.

## Examples

- **[starter](starter/)** One configuration across dev, test and prod, run by
  HCP Terraform with remote state.
- **[starter-azure-devops](starter-azure-devops/)** The same configuration, run
  by Azure Pipelines with state in Azure Blob Storage.
- **[multi-brand](multi-brand/)** Multiple brands sharing a baseline, with one
  tenant per brand and environment, run by HCP Terraform.

Each example is self-contained. Copy its folder to your repository root and
follow its README. All examples use the
[Authsignal provider](https://registry.terraform.io/providers/authsignal/authsignal)
`~> 3.7` and Terraform 1.11 or later.
