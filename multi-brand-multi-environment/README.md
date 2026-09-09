# Authsignal Terraform multi-brand, multi-environment example

Deploy one authentication policy to separate Authsignal tenants while giving each brand its own identity. This example uses version 3.6.0 of the [Authsignal Terraform provider](https://registry.terraform.io/providers/authsignal/authsignal/3.6.0/docs).

This example configures Brand One and Brand Two across `dev`, `test`, `preprod`, and `prod`. Each of the eight brand/environment pairs is a Terraform root under `live/`, with its own tenant, Management API credential, backend key, state, and provider lock file. Only real deployable roots live under `live/`.

## Architecture

```text
live/
  brand-one/
    brand.yaml
    dev/
    test/
    preprod/
    prod/
  brand-two/
    brand.yaml
    dev/
    test/
    preprod/
    prod/
modules/
  authsignal-tenant/
```

Each environment root configures its tenant and calls the shared `modules/authsignal-tenant` module, which declares the universal policy and theme resources:

| Resource address | Purpose |
| --- | --- |
| `module.tenant.authsignal_theme.this` | Applies the brand name, colour, logo, favicon, and optional watermark to the tenant's existing theme |
| `module.tenant.authsignal_action_configuration.classic` | Defines the CLASSIC action `classic` |
| `module.tenant.authsignal_rule.classic_anonymous_ip` | Challenges anonymous-network requests to `classic` |
| `module.tenant.authsignal_flow.sign_in` | Defines the FLOW action `sign-in` |

All eight roots use the same literal policy. The CLASSIC action challenges by default with Passkey or Email OTP and prefers Passkey. Its Anonymous IP rule also challenges with those methods. The `sign-in` flow blocks anonymous networks, verifies new devices with Passkey or Email OTP, and completes other sign-ins.

Brand differences come only from `brand.yaml`. The `environment` value adds a visible suffix to non-production tenant names, such as `Brand One (DEV)`; production uses `Brand One` without a suffix. It does not change policy. Brand Two omits the optional watermark, while Brand One supplies one. This keeps brand identity shared across its four environments while credentials and state remain isolated per tenant.

## Prerequisites

You need:

- Terraform 1.10 or later.
- One Authsignal tenant for each brand and environment.
- Each tenant's ID and Management API secret from **Settings > API keys** in the Authsignal Portal.
- An S3 state bucket and AWS credentials with access to the configured state objects.
- Passkey and Email OTP enabled in every tenant through the Authsignal Portal.

The committed lock files select Authsignal provider 3.6.0. Keep them committed.

Authenticator configuration is a Portal prerequisite and is not managed by this Terraform. Enable both Passkey and Email OTP before applying each tenant. A disabled method makes the CLASSIC action fail during apply, while the FLOW can publish and fail later when a user reaches its verification step.

## Configure and apply a tenant

The following workflow targets Brand One's development tenant. Repeat it with the matching values and secret for every tenant.

### 1. Configure the brand, tenant, and state

| File | Values to provide |
| --- | --- |
| `live/brand-one/brand.yaml` | Display name, primary colour, and optional logo, favicon, and watermark URLs |
| `live/brand-one/dev/terraform.tfvars` | Tenant ID placeholder `REPLACE_WITH_BRAND_ONE_DEV_TENANT_ID` and environment `dev`; add `authsignal_host` only for a non-default Management API host |
| `live/brand-one/dev/backend.hcl` | S3 bucket, region, and unique key `authsignal/brand-one/dev/terraform.tfstate` |

Brand Two follows the same layout: `live/brand-two/prod/terraform.tfvars` uses `REPLACE_WITH_BRAND_TWO_PROD_TENANT_ID`, and its backend key is `authsignal/brand-two/prod/terraform.tfstate`.

Supply the matching Management API secret without writing it to the repository:

```bash
read -rsp "Authsignal Management API secret: " AUTHSIGNAL_API_SECRET
printf '\n'
export AUTHSIGNAL_API_SECRET
```

The GitHub Actions matrices select a separate secret for every tenant. Examples are `AUTHSIGNAL_API_SECRET_ONE_DEV` and `AUTHSIGNAL_API_SECRET_TWO_PROD`.

### 2. Import the existing theme

Every Authsignal tenant already has a theme. Terraform can update that theme but cannot create it, so import it once per tenant before the first apply:

```bash
make import-theme BRAND=brand-one ENV=dev
```

The target initializes `live/brand-one/dev` and imports the empty ID into `module.tenant.authsignal_theme.this`. The empty ID requires the CLI import; a configuration-driven import block cannot represent it.

### 3. Plan and apply

```bash
make plan BRAND=brand-one ENV=dev
make apply BRAND=brand-one ENV=dev
```

`make plan` initializes the selected root and writes `live/brand-one/dev/tfplan`. Review that saved plan before `make apply`, which applies the same file. Create a fresh plan before every apply.

After applying, confirm the tenant's theme, `classic` action and Anonymous IP rule, and `sign-in` FLOW in the Portal. Manage the flow through Terraform so Portal edits do not conflict with later applies.

### 4. Destroy the managed resources

```bash
make destroy BRAND=brand-one ENV=dev
```

This target initializes the selected root and asks for confirmation before destroying its managed resources. It does not delete the Authsignal tenant or restore the theme's previous settings.

Remove the secret from your shell when finished:

```bash
unset AUTHSIGNAL_API_SECRET
```

## Repository commands

Per-tenant targets require both `BRAND` and `ENV`, and reject a path that does not exist.

```bash
make init BRAND=brand-one ENV=dev
make import-theme BRAND=brand-one ENV=dev
make plan BRAND=brand-one ENV=dev
make apply BRAND=brand-one ENV=dev
make destroy BRAND=brand-one ENV=dev
```

Repository-wide targets use the Brand One and Brand Two roots listed in the Makefile:

```bash
make fmt
make validate
make plan-all
```

`make fmt` formats Terraform recursively. `make validate` initializes without a backend and validates all eight configured roots. `make plan-all` plans those roots sequentially.

## Add another brand

Choose a new destination that does not already exist, then copy one of the existing brand directories so the new brand starts with all four environment roots and the provider lock files used by this repository:

```bash
cp -R live/brand-one live/brand-three
```

Then:

1. Remove any copied `.terraform/`, `terraform.tfstate*`, and `tfplan` local artifacts.
2. Replace the display name, primary colour, and asset URLs in `live/brand-three/brand.yaml`.
3. Replace the tenant ID in each environment's `terraform.tfvars`, using placeholders such as `REPLACE_WITH_BRAND_THREE_DEV_TENANT_ID` and retaining the existing environment value.
4. Change every `backend.hcl` key to the new brand, such as `authsignal/brand-three/dev/terraform.tfstate`, so each tenant has unique state.
5. Add `brand-three` to `BRANDS` in the Makefile and to the brand matrices in `.github/workflows/terraform.yml` and `.github/workflows/apply-environment.yml`, with a `brand_key` such as `THREE`.
6. Configure the four matching CI secrets, such as `AUTHSIGNAL_API_SECRET_THREE_DEV`, and the corresponding GitHub environments.
7. For each new tenant, enable Passkey and Email OTP, supply its Management API secret, import its theme, and plan and apply before the application tracks `sign-in`.

## Scope

This reference demonstrates different brand identities with one universal authentication policy and isolated tenant credentials and state. It does not vary authentication behaviour by brand or environment.

## References

- [Authsignal provider 3.6.0 release](https://github.com/authsignal/terraform-provider-authsignal/releases/tag/v3.6.0)
- [Authsignal provider 3.6.0 documentation](https://github.com/authsignal/terraform-provider-authsignal/tree/v3.6.0/docs)
