# Authsignal across several brands, on HCP Terraform

One repository manages every brand's Authsignal tenants in dev, test and
production. Open a pull request and HCP Terraform plans each affected
environment. Merge and each environment queues a run for approval.

## Projects and workspaces

- One project per brand.
- One workspace per tenant.
- A workspace holds one state file. Do not point two tenants at one workspace.

```text
brand-a (project)          brand-b (project)
  brand-a-dev                brand-b-dev
  brand-a-test               brand-b-test
  brand-a-prod               brand-b-prod
```

## Layout

```text
modules/authsignal/       shared configuration
  main.tf
  variables.tf
  versions.tf
  flows.tf
brands/
  brand-a/
    dev/ test/ prod/
      cloud.tf            workspace and project names
      main.tf             calls the module
      variables.tf
      terraform.tfvars    values for this tenant
      imports.tf          adopts the tenant's theme
  brand-b/
    ...
```

## Before you start

- An HCP Terraform account.
- One Authsignal tenant per environment.
- A Management API secret for each tenant, from **Settings > API keys** in the
  portal. This is not the Server API key.

## Set it up

### 1. Fork this repository

### 2. Connect GitHub

Go to **Settings > Version Control > Providers**, add GitHub, and install the
HCP Terraform GitHub App on your repository.

### 3. Create a project per brand

Open **Projects** and create `brand-a`. The name must match `project` in
`brands/brand-a/*/cloud.tf`.

### 4. Create a workspace per tenant

Inside the project, create each workspace with the **Version control
workflow**, pointed at your repository.

| Workspace | Terraform working directory |
|---|---|
| `brand-a-dev` | `brands/brand-a/dev` |
| `brand-a-test` | `brands/brand-a/test` |
| `brand-a-prod` | `brands/brand-a/prod` |

In **Settings > General**, turn **Auto-apply** off. Every run then waits for a
person, including dev. Turn it on for dev later if you want to.

In **Settings > Version Control**, choose **Always trigger runs** for
automatic run triggering, or set trigger patterns covering both the
environment folder and the shared module:

```text
brands/brand-a/dev/**
modules/**
```

A workspace with a working directory set only runs when files in that
directory change. Without this, a change to `modules/authsignal` triggers no
runs.

### 5. Add variables to each workspace

Add three **Environment variables**:

| Key | Value | Sensitive |
|---|---|---|
| `AUTHSIGNAL_HOST` | management API URL for your region, ending `/v1/management` | No |
| `AUTHSIGNAL_TENANT_ID` | the tenant's ID | No |
| `AUTHSIGNAL_API_SECRET` | the tenant's Management API secret | Yes |

Do not put tenant IDs or secrets in this repository.

### 6. Set your organization name

Change `organization = "your-org"` in every `cloud.tf`.

### 7. Start the first run

**Actions > Start new run** on each workspace, then approve it.

Automatic triggering does not always fire until a workspace has run once. After
the first run, pushes and pull requests trigger runs on their own.

### 8. Open a pull request

Change a value in `brands/brand-a/dev/terraform.tfvars` and open a pull
request. HCP Terraform links a plan for each affected workspace.

Merge, and each affected workspace queues a run. Approve each one in HCP
Terraform to apply it.

## First run

The first plan for a tenant reads:

```text
Plan: 1 to import, 2 to add, 1 to change, 0 to destroy.
```

The import is the theme, which every tenant already has. The additions are
the passkey configuration and the sign-in flow.

Leave `imports.tf` in place, or delete it after the first apply. See
[import blocks](https://developer.hashicorp.com/terraform/language/import).

## Plan from your machine

```bash
cd brands/brand-a/dev
terraform login
terraform init
terraform plan
```

Applies run from a merge only, and each one waits for approval.

## Add a brand

1. Copy a `brands/<brand>` folder.
2. Change the workspace and project names in each `cloud.tf`.
3. Change the values in each `terraform.tfvars`.
4. Create the project, the workspaces and their variables.

## Add an environment

1. Copy an environment folder inside a brand.
2. Change its `cloud.tf` and `terraform.tfvars`.
3. Create the workspace and its variables.

## Managed here

The theme, the passkey authenticator configuration, and a sign-in flow.

The provider also supports Email OTP, SMS, push, rules, value lists and
message overrides. Add them to `modules/authsignal`.

## Not covered

- Creating tenants. Create them in the portal first.
- Portal edits. The next apply replaces anything changed by hand.
- Deleting configuration.
