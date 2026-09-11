# Authsignal Terraform for several brands on HCP Terraform

Multiple brands, each with an Authsignal tenant in dev, test, and prod. HCP
Terraform watches the GitHub repository, plans pull requests, applies merges,
and stores state and Management API secrets. A shared baseline module defines
common configuration, and each brand module extends it. This example uses the
[Authsignal provider](https://registry.terraform.io/providers/authsignal/authsignal)
`~> 3.6` and Terraform 1.10 or later. For one brand, use `starter`.

## Layout

```text
README.md
.gitignore
modules/baseline/
  main.tf
  variables.tf
  outputs.tf
  flows/sign-in.json
brands/
  brand-a/
    main.tf
    variables.tf
    outputs.tf
    versions.tf
    brand.yaml
    flows/change-password.json
    environments/
      dev/ test/ prod/
        cloud.tf
        terraform.auto.tfvars
        main.tf
        variables.tf
        versions.tf
        .terraform.lock.hcl
  brand-b/
    ...
```

## How the layers fit

`modules/baseline` defines the theme structure and sign-in flow shared by every
brand. Brand identity enters through variables, while the module adds the
non-production suffix to theme names.

`brands/<brand>` reads identity from `brand.yaml`, calls the baseline, and adds
brand-specific flows. Brand A adds `change-password`; Brand B adds
`add-payment-method`.

`brands/<brand>/environments/<env>` selects the tenant. All six roots have
identical `main.tf`, `variables.tf`, and `versions.tf` files because the brand
module is always at `../..`. Only `cloud.tf` and `terraform.auto.tfvars` differ.

## Prerequisites

- **One Authsignal tenant per brand and environment.** This example uses six.
  The tenant ID and Management API secret are under Settings > API keys in the
  Authsignal Portal. Terraform configures existing tenants; it does not create
  them.
- **Passkey and Email OTP enabled in every tenant.** The included flows use both.
  A disabled method can be published but fails at runtime.
- **An HCP Terraform organisation** connected to GitHub as a VCS provider.
- **This folder at the root of a GitHub repository.**

## HCP Terraform setup

1. Create projects named `Brand A` and `Brand B` so access can be granted per
   brand.
2. In `Brand A`, create `authsignal-brand-a-dev`,
   `authsignal-brand-a-test`, and `authsignal-brand-a-prod`. Select `Version
   control workflow`, choose this repository, and set `Working Directory` to
   `brands/brand-a/environments/<env>`. Repeat for Brand B with
   `authsignal-brand-b-dev`, `authsignal-brand-b-test`, and
   `authsignal-brand-b-prod`.
3. Set each workspace's Terraform version to 1.10 or later.
4. Add these variables to each workspace:

   | Name | Kind | Value |
   | --- | --- | --- |
   | `tenant_id` | Terraform variable | That brand and environment's Authsignal tenant ID |
   | `AUTHSIGNAL_API_SECRET` | Sensitive environment variable | That tenant's Management API secret |

   The committed `terraform.auto.tfvars` sets `environment`.
5. Enable auto-apply for both `-dev` workspaces and disable it for the `-test`
   and `-prod` workspaces.
6. In each workspace's Version Control settings, trigger runs only for changes
   to `brands/<brand>/**` or `modules/**`.
7. Set the `organization` value in all six
   `brands/*/environments/*/cloud.tf` files.

## How a change flows

A change under `modules/baseline` plans all six workspaces. A change under
`brands/brand-a` plans only Brand A's three workspaces.

A pull request starts speculative plans in the matching workspaces and posts
them as checks. After a merge to `main`, the `-dev` workspaces apply
automatically. The `-test` and `-prod` workspaces wait at `Needs Confirmation`
until a user with apply permission confirms each run.

Every plan runs `terraform validate`. The Authsignal provider validates flow
JSON, including unknown keys, dangling `childNodeId` references, and unused
rules, before an apply can reach production.

## Running locally

```bash
terraform login # stores an HCP Terraform token
cd brands/brand-a/environments/dev
terraform init
terraform plan
```

The `cloud` block runs the plan in `authsignal-brand-a-dev` with that workspace's
`tenant_id` and `AUTHSIGNAL_API_SECRET`, then streams the output locally. To
validate without HCP Terraform access, run
`terraform init -backend=false && terraform validate`.

## Adding a brand

1. Run `cp -R brands/brand-b brands/brand-c`, then remove
   `brands/brand-c/environments/*/.terraform`.
2. Update the display name, colour, and image URLs in
   `brands/brand-c/brand.yaml`. Remove `watermark_url` if unused.
3. Replace `brands/brand-c/flows/` with the brand's Authsignal Portal exports.
   Update the `authsignal_flow` resources in `main.tf` and the `merge()` in
   `outputs.tf`; remove both if the brand uses only the baseline.
4. Set each workspace name in `brands/brand-c/environments/*/cloud.tf` to
   `authsignal-brand-c-<env>`. The other root files remain unchanged.
5. Create a `Brand C` project and three workspaces with trigger paths
   `brands/brand-c/**` and `modules/**`.

The copied roots retain the permanent theme `import` block, so no manual import
is required.

## Adding a flow

For one brand, save the export as
`brands/<brand>/flows/<action-code>.json`, add an `authsignal_flow` resource to
that brand's `main.tf`, and add its version to the `merge()` in `outputs.tf`.

For every brand, save the export under `modules/baseline/flows/`, then add the
resource to `modules/baseline/main.tf` and its version to `outputs.tf`.

To export a flow from the Authsignal Portal:

1. Open Actions and edit the FLOW action.
2. Export the flow as JSON. The provider accepts the exported `actionNodes` and
   `rules` keys.
3. Save it as `<action-code>.json`, replacing the previous export.
4. Commit the change, open a pull request, and review the plans.

Once Terraform manages an action, Authsignal Portal edits are overwritten by
the next apply.

## Adding an environment

For each brand, copy `brands/<brand>/environments/dev` to
`brands/<brand>/environments/staging`, remove its `.terraform` directory, set the
workspace name in `cloud.tf`, and set `environment = "staging"` in
`terraform.auto.tfvars`.

Add `staging` to the `environment` validation in
`modules/baseline/variables.tf`, every `brands/*/variables.tf`, and every
`brands/*/environments/*/variables.tf` so the roots remain identical. Create one
workspace per brand, enable Passkey and Email OTP in the new tenants, and keep
the copied theme `import` block.

## Not covered

- **One brand.** See `starter`.
- **Running Terraform in your own CI.** See `starter-azure-devops`.
- **Replacing a shared flow for one brand.** Move the flow from the baseline to
  each brand module.
- **Creating Authsignal tenants.** Terraform configures existing tenants.
- **Destroy.** Removing a brand's configuration should require deliberate
  action.
