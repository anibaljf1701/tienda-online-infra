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

Each environment (`dev`, `prod`) has its own isolated set of resources and its own Terraform state file stored in the `tienda-tfstate` S3 bucket.

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
terragrunt run --all apply --terragrunt-non-interactive

# 5. Open the product catalog
# http://localhost:4566/tienda-dev-static/index.html
```

> **Note:** The `--terragrunt-non-interactive` flag skips the confirmation prompts. Remove it if you want to review the plan before applying.

---

## Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.6.0 | Infrastructure provisioning |
| Terragrunt | >= 0.67.0 | DRY wrapper — remote state, provider generation, dependency management |
| AWS Provider | ~> 6.54.0 | AWS resource management |
| MiniStack | 1.4.x | Local AWS emulator |

---

## Why Terragrunt?

The `dev` and `prod` environments share identical infrastructure logic. Without Terragrunt, `providers.tf`, `variables.tf`, `outputs.tf`, and `main.tf` would be duplicated across both environments. Terragrunt eliminates that duplication:

- **`root.hcl`** — root marker file; the actual remote state and provider generation live in each env-level `terragrunt.hcl`
- **`env.hcl`** — single file per environment declaring `environment = "dev"` or `"prod"`
- **Per-stack `terragrunt.hcl`** — declares the module source and cross-stack dependencies only; all other config is inherited

---

## Directory Structure

```
tienda_online/
├── .gitignore
├── README.md
└── terraform/
    ├── root.hcl                    ← root marker (empty); env config lives in live/{env}/terragrunt.hcl
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

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker | >= 24 | [docs.docker.com](https://docs.docker.com/engine/install/) |
| MiniStack | 1.4.x | `docker pull ministackorg/ministack` |
| Terraform | >= 1.6.0 | [developer.hashicorp.com](https://developer.hashicorp.com/terraform/install) |
| Terragrunt | >= 0.67.0 | see below |
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
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool | grep '"dynamodb"'
# Expected: "dynamodb": "available"
```

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
terragrunt run --all apply
```

Terragrunt resolves dependency order automatically — SNS/SQS are applied in the correct sequence.

### Deploy all environments

```bash
cd terraform/live
terragrunt run --all apply
```

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
| prod/... | `live/prod/.../terraform.tfstate` |

Inspect state files:

```bash
aws --profile local s3 ls s3://tienda-tfstate --recursive
```

---

## Cross-Stack Dependencies

SNS and SQS have a circular dependency by design (each needs the other's ARN for the subscription/policy). Terragrunt resolves this with `dependency` blocks and `mock_outputs` for plan/validate:

```
sns_alerts  ──depends_on──▶  sqs_orders (needs queue_arn)
sqs_orders  ──depends_on──▶  sns_alerts (needs topic_arn)
```

On first `apply`, Terragrunt applies each stack sequentially and wires the real ARNs automatically.

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

## Dev vs Prod Differences

The only source of environment-specific config is `env.hcl`:

```hcl
# live/dev/env.hcl
locals {
  environment = "dev"
}

# live/prod/env.hcl
locals {
  environment = "prod"
}
```

That single value propagates via the environment-level `terragrunt.hcl` to every stack's provider, resource names (`tienda-dev-*` vs `tienda-prod-*`), tags, and state key paths. No Terraform files are duplicated between environments.
