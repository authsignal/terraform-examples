# Authsignal Terraform across dev, test and prod on Azure DevOps

One Authsignal configuration across three tenants. Azure Pipelines runs
Terraform, Azure Blob Storage holds state, and Azure DevOps variable groups hold
the Management API secrets. The Terraform configuration matches `starter`.
This example uses the
[Authsignal provider](https://registry.terraform.io/providers/authsignal/authsignal)
`~> 3.6` and Terraform 1.10 or later.

## Layout

```text
azure-pipelines.yml
backend.hcl
pipelines/templates/
  install-terraform.yml
  terraform-env.yml
  stages.yml
modules/authsignal-tenant/
  main.tf
  variables.tf
  outputs.tf
  flows/*.json
environments/dev|test|prod/
  terraform.auto.tfvars
  main.tf
  variables.tf
  versions.tf
  .terraform.lock.hcl
```

Only `terraform.auto.tfvars` differs between the three environment roots. Their
`main.tf`, `variables.tf`, and `versions.tf` files are identical.

## Prerequisites

- **Three Authsignal tenants.** The tenant ID and Management API secret are under
  Settings > API keys in the Authsignal Portal. Terraform configures existing
  tenants; it does not create them.
- **Passkey and Email OTP enabled in every tenant.** The included flows use both.
  A disabled method can be published but fails at runtime.
- **An Azure subscription** with permission to create a resource group and
  storage account.
- **An Azure DevOps project containing this repository** with permission to
  create service connections, variable groups, Environments, and pipelines.

## One-time Azure setup for state

Create a resource group, storage account, and blob container. Storage account
names must be globally unique and contain only lowercase letters and numbers.

```bash
LOCATION=uksouth
RG=rg-authsignal-tfstate
SA=stauthsignaltfstate # unique, 3-24 characters, a-z0-9
CONTAINER=tfstate

az group create --name "$RG" --location "$LOCATION"

az storage account create --name "$SA" --resource-group "$RG" \
  --location "$LOCATION" --sku Standard_ZRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false \
  --allow-shared-key-access false

# Enable recovery from changes and deletion.
az storage account blob-service-properties update \
  --account-name "$SA" --resource-group "$RG" \
  --enable-versioning true --enable-delete-retention true \
  --delete-retention-days 30

az storage container create --name "$CONTAINER" \
  --account-name "$SA" --auth-mode login
```

Disabling shared-key access requires `use_azuread_auth = true` in `backend.hcl`,
so state is accessible only through a Microsoft Entra ID identity.

Grant the pipeline service principal data access to the container. The service
connection's subscription role does not grant blob data access. Azure DevOps
names its app registration `<organisation>-<project>-<subscription-id>`, not
after the service connection. Read the client ID from Project settings > Service
connections > `authsignal-terraform`.

```bash
SP_CLIENT_ID=<client-id-from-the-service-connection>
SP_OBJECT_ID=$(az ad sp show --id "$SP_CLIENT_ID" --query id -o tsv)
SUB_ID=$(az account show --query id -o tsv)

az role assignment create --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$SA"
```

For local access, grant your user the same role with
`--assignee-object-id "$(az ad signed-in-user show --query id -o tsv)"
--assignee-principal-type User`.

Blob data role assignments can take several minutes to propagate. An immediate
`AuthorizationPermissionMismatch` while listing blobs usually means the role is
still propagating.

Set the non-secret storage values in `backend.hcl`.

## Azure DevOps setup

1. **ARM service connection.** Under Project settings > Service connections,
   create an `Azure Resource Manager` connection using `Workload Identity
   federation`. Scope it to the subscription containing the state account and
   name it `authsignal-terraform`, matching `serviceConnection` in
   `pipelines/templates/stages.yml`. It provides state access only.
2. **Variable groups.** Under Pipelines > Library, create groups named exactly
   `authsignal-dev`, `authsignal-test`, and `authsignal-prod`. Each group must
   contain `AUTHSIGNAL_TENANT_ID` and a secret `AUTHSIGNAL_API_SECRET` for its
   tenant.

   All three groups must exist before any stage runs, including dev. Azure DevOps
   expands every stage before starting the pipeline, so a missing group stops the
   entire run. Use placeholder values until a tenant is available.
3. **Environments and approval.** Create Azure DevOps Environments named exactly
   `authsignal-dev`, `authsignal-test`, and `authsignal-prod`. On
   `authsignal-prod`, configure an approval under Approvals and checks. The
   pipeline contains no approval step.
4. **Register the pipeline.** Select Existing Azure Pipelines YAML file and use
   `/starter-azure-devops/azure-pipelines.yml`. If you copy this example's
   contents to the repository root, set `workingRoot` to `.` and remove the
   `starter-azure-devops/` prefix from the trigger paths.
5. **Authorise resources.** On the first run, approve access to the variable
   groups, Environments, and service connection.

## What the pipeline does

- **Validate.** Runs `terraform fmt -recursive -check`, then
  `terraform init -backend=false` and `terraform validate` in each root. It needs
  no state or credentials, so it can run on pull requests. The provider validates
  each flow JSON document during this stage.
- **Dev, Test, and Prod.** On `main`, each stage initialises the shared backend
  with a unique state key, validates, creates `tfplan`, and applies that plan.
  Stages run in order from dev to test to prod.
- **Production gate.** The approval belongs to the `authsignal-prod` Environment,
  not the YAML.

## Running locally

Run `az login` as a user with `Storage Blob Data Contributor` on the container.

```bash
cd environments/dev

export TF_VAR_tenant_id=<your-dev-tenant-id>
read -rsp "Authsignal Management API secret: " AUTHSIGNAL_API_SECRET
printf '\n'
export AUTHSIGNAL_API_SECRET

terraform init -backend-config=../../backend.hcl -backend-config="key=dev.tfstate"
terraform plan
terraform apply

unset TF_VAR_tenant_id AUTHSIGNAL_API_SECRET
```

The committed `terraform.auto.tfvars` sets `environment`. To validate without
Azure access, run `terraform init -backend=false && terraform validate`.

## Exporting a flow from the Portal

1. In the Authsignal Portal, open Actions and edit the FLOW action.
2. Export the flow as JSON. The provider accepts the exported `actionNodes` and
   `rules` keys.
3. Save it as `modules/authsignal-tenant/flows/<action-code>.json`, replacing the
   previous export.
4. For a new action, add an `authsignal_flow` resource to
   `modules/authsignal-tenant/main.tf` and add it to `outputs.tf` to include its
   version in the run log.
5. Commit the change and open a pull request.

Once Terraform manages an action, Authsignal Portal edits are overwritten by
the next apply.

## Adding an environment

To add `staging`:

1. Copy `environments/dev` to `environments/staging`, remove its `.terraform`
   directory, and set `environment = "staging"` in `terraform.auto.tfvars`.
2. Add `staging` to the `environment` validation in
   `modules/authsignal-tenant/variables.tf` and every
   `environments/*/variables.tf` so the roots remain identical.
3. Add `staging` to the `environments` default in
   `pipelines/templates/stages.yml`, then add its stage with the required
   `dependsOn`.
4. Create the `authsignal-staging` variable group and Environment.
5. Enable Passkey and Email OTP in the tenant, then merge. The copied root keeps
   the permanent theme `import` block, so no manual import is required. The first
   apply creates `staging.tfstate`.

## Not covered

- **Multiple brands, products, or business units.** See `multi-brand`.
- **Running on HCP Terraform.** See `starter`.
- **Creating Authsignal tenants.** Terraform configures existing tenants.
- **Provider download troubleshooting on restricted agents.**
- **Destroy.** Removing a tenant's configuration should require deliberate
  action.
