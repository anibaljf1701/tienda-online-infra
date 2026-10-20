# Tienda Online Infrastructure

Terraform + Terragrunt infrastructure for a local online store demo using **MiniStack** (local AWS emulator on `localhost:4566`).

Provisions S3 static website hosting, SQS order queues, SNS alerts, DynamoDB products table, and Secrets Manager — isolated per environment, with remote state stored in MiniStack S3.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   MiniStack (localhost:4566)             │
│                                                         │
│  ┌──────────┐    ┌─────────┐    ┌───────────────────┐  │
│  │ S3 Static│    │   SNS   │───▶│   SQS Orders      │  │
│  │ Website  │    │  Alerts │    │   Queue + DLQ     │  │
│  └──────────┘    └─────────┘    └───────────────────┘  │
│                                                         │
│  ┌──────────────────┐    ┌─────────────────────────┐   │
│  │  DynamoDB        │    │  Secrets Manager        │   │
│  │  Products Table  │    │  db_password secret     │   │
│  └──────────────────┘    └─────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

Each environment (`dev`, `stg`, `prod`) has its own isolated set of resources and Terraform state files in `tienda-tfstate`.

---

## Quick Start

Clone the repo and follow these steps to have the full infrastructure running locally in under 5 minutes.

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/tienda-online-infra.git
cd tienda-online-infra

# 2. Start MiniStack
docker run --rm -d --name ministack -p 4566:4566 ministackorg/ministack

# 3. Create the remote state bucket
aws --profile local s3 mb s3://tienda-tfstate

# 4. Deploy dev environment
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply

# 5. Open the product catalog
# http://localhost:4566/tienda-dev-static/index.html
```

> **Note:** Review the plan output before applying. Do not use auto-approve for a first deployment or production changes.

---

## Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.6.0 | Infrastructure provisioning |
| Terragrunt | >= 1.1.0 | DRY wrapper — remote state, provider generation, dependency management |
| AWS Provider | ~> 6.54.0 | AWS resource management |
| MiniStack | 1.4.x | Local AWS emulator |

---

## Why Terragrunt?

The `dev`, `stg`, and `prod` environments share the same Terraform modules. Terragrunt keeps the environment configuration and stack dependencies in one source of truth:

- **`root.hcl`** — shared remote-state, provider generation, tags, and common inputs
- **`env.hcl`** — one file per environment declaring `environment = "dev"`, `"stg"`, or `"prod"`
- **Per-stack `terragrunt.hcl`** — declares the module source and cross-stack dependencies; shared config is inherited from `root.hcl`

---

## Directory Structure

```
tienda_online/
├── .gitignore
├── README.md
└── terraform/
    ├── root.hcl                    ← shared backend, provider, and common inputs
    ├── modules/                    ← reusable Terraform modules (no Terragrunt awareness)
    │   ├── s3_website/
    │   │   ├── versions.tf
    │   │   ├── variables.tf
    │   │   ├── locals.tf
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── templates/
    │   │       ├── index.html.tftpl
    │   │       └── error.html
    │   ├── sqs_orders/
    │   ├── sns_alerts/
    │   ├── dynamodb_products/
    │   └── secrets/
    └── live/                       ← Terragrunt live infrastructure
        ├── dev/
        │   ├── env.hcl             ← environment = "dev"
        │   ├── s3_website/
        │   │   └── terragrunt.hcl
        │   ├── sqs_orders/
        │   │   └── terragrunt.hcl
        │   ├── sns_alerts/
        │   │   └── terragrunt.hcl
        │   ├── dynamodb_products/
        │   │   └── terragrunt.hcl
        │   └── secrets/
        │       └── terragrunt.hcl
        ├── stg/
        │   ├── env.hcl             ← environment = "stg"
        │   ├── s3_website/terragrunt.hcl
        │   ├── sqs_orders/terragrunt.hcl
        │   ├── sns_alerts/terragrunt.hcl
        │   ├── dynamodb_products/terragrunt.hcl
        │   └── secrets/terragrunt.hcl
        └── prod/
            ├── env.hcl             ← environment = "prod"
            ├── s3_website/
            │   └── terragrunt.hcl
            ├── sqs_orders/
            │   └── terragrunt.hcl
            ├── sns_alerts/
            │   └── terragrunt.hcl
            ├── dynamodb_products/
            │   └── terragrunt.hcl
            └── secrets/
                └── terragrunt.hcl
```

    `terraform/live` is the only supported deployment root. Do not run Terraform directly from a module directory or maintain separate per-environment root modules.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker | >= 24 | [docs.docker.com](https://docs.docker.com/engine/install/) |
| MiniStack | 1.4.x | `docker pull ministackorg/ministack` |
| Terraform | >= 1.6.0 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Terragrunt | >= 1.1.0 | see below |
| AWS CLI | v2 | `sudo /tmp/aws/install` after download |

### Start MiniStack

MiniStack is the local AWS emulator. Start it before running any Terragrunt commands:

```bash
docker run --rm -d \
  --name ministack \
  -p 4566:4566 \
  ministackorg/ministack
```

Verify it is healthy:

```bash
curl -s http://localhost:4566/_ministack/health | python3 -m json.tool | grep '"dynamodb"'
# Expected: "dynamodb": "available"
```

`/_ministack/health` is MiniStack's documented health endpoint. MiniStack also accepts `/_localstack/health` for LocalStack compatibility.

### Install Terraform (Linux)

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
terraform -version
```

### Install Terragrunt (Linux)

```bash
# Download latest release
TGVERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest \
  | grep tag_name | cut -d '"' -f 4)

curl -Lo /tmp/terragrunt \
  "https://github.com/gruntwork-io/terragrunt/releases/download/${TGVERSION}/terragrunt_linux_amd64"

chmod +x /tmp/terragrunt
sudo mv /tmp/terragrunt /usr/local/bin/terragrunt

terragrunt --version
```

### Install AWS CLI v2 (Linux)

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp/
sudo /tmp/aws/install --update
aws --version  # must show aws-cli/2.x.x
```

### Configure AWS CLI local profile

Add the following to your AWS config files (create them if they don't exist):

```bash
# ~/.aws/credentials
[local]
aws_access_key_id = test
aws_secret_access_key = test

# ~/.aws/config
[profile local]
region = us-east-1
output = json
endpoint_url = http://localhost:4566
```

Verify the profile works:

```bash
aws --profile local s3 ls
# Returns empty list if MiniStack is running and no buckets exist yet
```

---

## Local Workflow

### Verify MiniStack is running

```bash
docker ps | grep ministack
```

### Create the remote state bucket (first time only)

```bash
aws --profile local s3 mb s3://tienda-tfstate
```

### Deploy a single stack

```bash
cd terraform/live/dev/dynamodb_products
terragrunt init
terragrunt plan
terragrunt apply
```

### Deploy all stacks in an environment

```bash
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply
```

Terragrunt resolves dependency order automatically — SNS/SQS are applied in the correct sequence.

### Deploy all environments (local MiniStack only)

```bash
cd terraform/live
terragrunt run --all plan
terragrunt run --all apply
```

This command applies `dev`, `stg`, and `prod`; deploy one environment at a time for AWS.

---

## Remote State

Each stack stores its state in MiniStack S3 under the path derived from the directory structure:

| Stack | State key |
|-------|-----------|
| dev/s3_website | `live/dev/s3_website/terraform.tfstate` |
| dev/sqs_orders | `live/dev/sqs_orders/terraform.tfstate` |
| dev/sns_alerts | `live/dev/sns_alerts/terraform.tfstate` |
| dev/dynamodb_products | `live/dev/dynamodb_products/terraform.tfstate` |
| dev/secrets | `live/dev/secrets/terraform.tfstate` |
| stg/... | `live/stg/.../terraform.tfstate` |
| prod/... | `live/prod/.../terraform.tfstate` |

Inspect state files:

```bash
aws --profile local s3 ls s3://tienda-tfstate --recursive
```

---

## Cross-Stack Dependencies

The SNS stack depends on SQS because it needs the queue ARN and URL to create the subscription and queue policy. The dependency is one-way; there is no cycle:

```
sns_alerts  ──depends_on──▶  sqs_orders (needs queue_arn and queue_url)
```

Terragrunt applies SQS before SNS and passes the real queue outputs to the SNS stack. `mock_outputs` are only for `validate`/`plan` when the dependency has not yet been deployed; they are not used by `apply`.

---

## Verification Commands

After `terragrunt run --all apply` in `live/dev/`:

```bash
# S3 static website
aws --profile local s3 ls
aws --profile local s3api get-bucket-website --bucket tienda-dev-static

# Browse the product catalog
# http://localhost:4566/tienda-dev-static/index.html

# SQS
aws --profile local sqs list-queues

# SNS
aws --profile local sns list-topics

# DynamoDB
aws --profile local dynamodb list-tables
aws --profile local dynamodb scan --table-name tienda-dev-products

# Secrets Manager
aws --profile local secretsmanager list-secrets

# Remote state
aws --profile local s3 ls s3://tienda-tfstate --recursive
```

---

## Environment Differences

The only source of environment-specific config is `env.hcl`:

```hcl
# live/dev/env.hcl
locals {
  environment = "dev"
}

# live/stg/env.hcl
locals {
  environment = "stg"
}

# live/prod/env.hcl
locals {
  environment = "prod"
}
```

That value is read by `root.hcl` and propagates to every stack's provider, resource names (`tienda-dev-*`, `tienda-stg-*`, `tienda-prod-*`), tags, and state key paths. All three environments use the same modules and `terraform/live` Terragrunt stacks. There are no separate Terraform environment roots; `live` is the source of truth.

---

## Deploying to AWS (`dev`, `stg`, `prod`)

The current configuration is for MiniStack only and remains unchanged for local use. Do not point it at AWS as-is: the provider and S3 backend use `localhost:4566` and test credentials, and the website module grants public object reads. Make the following changes in an AWS-specific copy/branch of the configuration before any AWS deployment; never mix the MiniStack and AWS state or credentials.

### Required configuration changes

1. **Use AWS credentials and provider settings.** Keep the current `terraform/root.hcl` for MiniStack. For AWS, create a separate root config and have the live stacks include it in the AWS deployment branch/configuration. In the AWS provider block remove `access_key`, `secret_key`, `skip_credentials_validation`, `skip_metadata_api_check`, `skip_requesting_account_id`, and the complete `endpoints` block. Use AWS CLI SSO credentials locally or an IAM role/OIDC in CI; never commit credentials. Set the AWS region explicitly per environment. The AWS provider should rely on its normal credential chain, for example:

   ```hcl
   provider "aws" {
     region = "us-east-1"

     default_tags {
       tags = {
         Project     = "tienda"
         Environment = "dev"
         ManagedBy   = "Terraform"
       }
     }
   }
   ```

2. **Use a dedicated AWS remote-state bucket.** Create it outside these application stacks in the target AWS account. Enable versioning, server-side encryption, S3 public-access blocking, and least-privilege access for deployment roles. Use a globally unique bucket name and a separate bucket/account for production where possible. In the AWS `remote_state.config`, remove MiniStack's `endpoint`, test `access_key`/`secret_key`, all `skip_*` options, and `force_path_style`; set the AWS bucket, region, encryption, and a unique key per environment/stack. Enable S3 lock files with `use_lockfile = true` and raise every Terraform `required_version` minimum to `>= 1.10.0`. Never point AWS at `tienda-tfstate` in MiniStack or reuse local state.
3. **Deploy the existing `stg` environment.** `terraform/live/stg` already contains `env.hcl` and all five stack configs. It is accepted by the module environment validations and has isolated names/state keys. Include `stg` in CI plan checks and deploy from that directory, just as with dev/prod.
4. **Keep public S3 behavior local; change it for AWS.** The current S3 module deliberately disables all four public-access-block settings and attaches a policy granting `s3:GetObject` to `Principal = "*"`. Leave it unchanged for the local MiniStack demo. For AWS, set all four public-access-block settings to `true`, remove that public policy, and keep the bucket private. Add a CloudFront distribution using the S3 REST endpoint (not the S3 website endpoint), configure Origin Access Control (OAC), and add a bucket policy that grants `s3:GetObject` only to `cloudfront.amazonaws.com`, conditioned on the specific CloudFront distribution ARN. Configure TLS and DNS as required. Implement these as AWS-specific module inputs/resources so MiniStack behavior remains local-only; inspect the plan and resulting bucket policy before applying.
5. **Review production controls.** Use separate AWS accounts or strong role boundaries for dev/stg/prod; define least-privilege deployment permissions; review SQS retention/visibility/redrive settings, SNS delivery/alarms, DynamoDB backups/PITR and encryption, and Secrets Manager rotation/access. State and plan artifacts can contain sensitive values: restrict access, encrypt them, and do not print secrets in CI logs. Deploy one environment at a time with production approvals.

### Suggested AWS deployment flow

After creating the AWS-specific root/provider/backend and making the S3 website private behind CloudFront, configure AWS SSO/role access and verify the active account and region before every deployment. Deploy environments separately, review plans, and apply only the reviewed plan:

```bash
aws sts get-caller-identity --profile tienda-dev
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply
```

Repeat with the appropriate profile and directory for `stg` and `prod`. Use production approvals in CI/CD, and do not run `terragrunt run --all apply` from `terraform/live` against AWS because that applies every environment in one operation.

### Current review notes

- Product `price` and `stock` are DynamoDB Number attributes. `stock` is a unit count; the catalog shows zero as out of stock and quantities of five or less as low stock. Review the Terraform plan when upgrading an existing deployment so seeded item values change from strings to numbers; manually managed records need their own migration.
- MiniStack's documented health route is `/_ministack/health`. It also accepts `/_localstack/health` as a LocalStack-compatible alias.
- The project provisions foundational demo services, not a complete production commerce platform. Authentication, checkout/payment processing, application runtime, observability, backups, and a CDN/domain are outside the current modules.
