# Authsignal Terraform across dev, test and prod on HCP Terraform

One Authsignal configuration across three tenants. HCP Terraform watches the
GitHub repository, plans pull requests, applies merges, and stores state and the
Management API secret. This example uses the
[Authsignal provider](https://registry.terraform.io/providers/authsignal/authsignal)
`~> 3.7` and Terraform 1.11 or later.

## Layout

```text
README.md
.gitignore
modules/authsignal-tenant/
  main.tf
  variables.tf
  outputs.tf
  flows/
    sign-in.json
    sign-up.json
environments/
  dev/ test/ prod/
    cloud.tf               # HCP Terraform organisation and workspace
    terraform.auto.tfvars  # environment name
    main.tf
    variables.tf
    versions.tf
    .terraform.lock.hcl
```

Each environment root calls `../../modules/authsignal-tenant`, so all three use
the same theme and flows. Their `main.tf`, `variables.tf`, and `versions.tf`
files are identical; only `cloud.tf` and `terraform.auto.tfvars` differ.

Each root keeps a permanent `import` block that adopts the tenant's existing
theme, which the provider can update but not create; `tenant_id` is the import ID.

## Prerequisites

- **Three Authsignal tenants.** The tenant ID and Management API secret are under
  Settings > API keys in the Authsignal Portal. Terraform configures existing
  tenants; it does not create them.
- **SMTP delivery details for every tenant.** Email OTP sends over SMTP, so each
  tenant needs a host, username, sender address, and password.
- **An HCP Terraform organisation** connected to GitHub as a VCS provider.
- **This folder at the root of a GitHub repository.**

Terraform configures the Passkey and Email OTP authenticators in
`modules/authsignal-tenant/main.tf`, so neither needs enabling in the Portal
first. Passkey uses the relying party `mfa.authsignal.com`. Email OTP sends
over SMTP on port 465 with TLS; set `smtp_host`, `smtp_user`, `smtp_from` and
the non-secret `smtp_credentials_version` marker in each environment's
`terraform.auto.tfvars`, and bump the marker to resend the credentials.
`smtp_password` has no default: it is an ephemeral, sensitive variable that
must be supplied at plan and apply time, and Terraform keeps it out of state
and plan files.

The `sign-in` flow challenges risky sign-ins and completes verified ones at their
own completion node; `sign-up` enrolls a Passkey or Email OTP authenticator
before completing. Both offer Passkey and Email OTP.

## HCP Terraform setup

1. Create a project, for example `Authsignal`.
2. Create workspaces named `authsignal-dev`, `authsignal-test`, and
   `authsignal-prod`. Select `Version control workflow`, choose this repository,
   and set `Working Directory` to `environments/dev`, `environments/test`, and
   `environments/prod`, respectively.
3. Set each workspace's Terraform version to 1.11 or later.
4. Add these variables to each workspace:

   | Name | Kind | Value |
   | --- | --- | --- |
   | `tenant_id` | Terraform variable | That environment's Authsignal tenant ID |
   | `AUTHSIGNAL_API_SECRET` | Sensitive environment variable | That environment's Management API secret |
   | `smtp_password` | Sensitive Terraform variable | That tenant's SMTP password |

   The committed `terraform.auto.tfvars` sets `environment`.
5. Enable auto-apply for `authsignal-dev` and disable it for `authsignal-test`
   and `authsignal-prod`.
6. In each workspace's Version Control settings, trigger runs only for changes
   to `environments/<env>/**` or `modules/**`.
7. Set the `organization` value in all three `environments/*/cloud.tf` files.

## How a change flows

A pull request starts a speculative plan in all three workspaces and posts each
plan as a check. Speculative plans cannot apply.

After a merge to `main`, `authsignal-dev` applies automatically.
`authsignal-test` and `authsignal-prod` wait at `Needs Confirmation` until a user
with apply permission confirms each run. Workspace permissions control access to
this approval.

Every plan runs `terraform validate`. The Authsignal provider validates flow
JSON, including unknown keys, dangling `childNodeId` references, and unused
rules, before an apply can reach production.

## Running locally

```bash
terraform login # stores an HCP Terraform token
cd environments/dev
terraform init
terraform plan
```

The `cloud` block runs the plan in `authsignal-dev` with that workspace's
`tenant_id` and `AUTHSIGNAL_API_SECRET`, then streams the output locally. No
tenant credentials are required on the local machine.

To validate without HCP Terraform access:

```bash
terraform init -backend=false && terraform validate
```

## Exporting a flow from the Portal

1. In the Authsignal Portal, open Actions and edit the FLOW action.
2. Export the flow as JSON. The provider accepts the exported `actionNodes` and
   `rules` keys.
3. Save it as `modules/authsignal-tenant/flows/<action-code>.json`, replacing the
   previous export.
4. For a new action, add a resource to `modules/authsignal-tenant/main.tf`:

   ```hcl
   resource "authsignal_flow" "change_password" {
     action_code = "change-password"
     flow        = file("${path.module}/flows/change-password.json")

     depends_on = [
       authsignal_passkey_authenticator_configuration.passkey,
       authsignal_email_otp_authenticator_configuration.email_otp,
     ]
   }
   ```

   Keep the `depends_on` block for any flow that offers Passkey or Email OTP, so
   both authenticators exist before the flow is published.

   Add it to `outputs.tf` to include its version in the run log.
5. Commit the change, open a pull request, and review the three plans.

Once Terraform manages an action, Authsignal Portal edits are overwritten by
the next apply.

## Adding an environment

To add `staging`:

1. Run `cp -R environments/dev environments/staging`, then remove
   `environments/staging/.terraform`.
2. Set the workspace name in `environments/staging/cloud.tf` to
   `authsignal-staging` and set `environment = "staging"` in
   `terraform.auto.tfvars`.
3. Add `staging` to the `environment` validation in
   `modules/authsignal-tenant/variables.tf` and every
   `environments/*/variables.tf` so the roots remain identical.
4. Create the `authsignal-staging` workspace with Working Directory
   `environments/staging`, its own `tenant_id` and `AUTHSIGNAL_API_SECRET`, and
   the same trigger-path pattern.
5. Add the tenant's `smtp_password` to the workspace, then merge. The copied root
   keeps the permanent theme `import` block, so no manual import is required.

## Not covered

- **Multiple brands, products, or business units.** See `multi-brand`.
- **Running Terraform in your own CI.** See `starter-azure-devops`.
- **Creating Authsignal tenants.** Terraform configures existing tenants.
- **Drift detection, policy as code, and scheduled runs.**
- **Destroy.** Removing a tenant's configuration should require deliberate
  action.
