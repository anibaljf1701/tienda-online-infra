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

Each environment (`dev`, `prod`; `stg` can be added following the AWS guidance below) has its own isolated set of resources and Terraform state files in `tienda-tfstate`.

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

The `dev` and `prod` environments share identical infrastructure logic. Without Terragrunt, `providers.tf`, `variables.tf`, `outputs.tf`, and `main.tf` would be duplicated across both environments. Terragrunt eliminates that duplication:

- **`root.hcl`** — shared remote-state, provider generation, tags, and common inputs
- **`env.hcl`** — single file per environment declaring `environment = "dev"` or `"prod"`
- **Per-stack `terragrunt.hcl`** — declares the module source and cross-stack dependencies; shared config is inherited from `root.hcl`

---

## Directory Structure

```
tienda_online/
├── .gitignore
├── README.md
└── terraform/
    ├── root.hcl                    ← shared backend, provider, and common inputs
    ├── environments/               ← standalone Terraform roots (dev/prod; duplicate module wiring)
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
        ├── prod/
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
        └── stg/                    ← same env.hcl + stack directories when added
```

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
terragrunt run --all plan
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

That value is read by `root.hcl` and propagates to every stack's provider, resource names (`tienda-dev-*` vs `tienda-prod-*`), tags, and state key paths. The Terragrunt stacks reuse modules, but `terraform/environments/dev` and `terraform/environments/prod` are separate Terraform roots that duplicate module wiring; choose one deployment workflow and avoid managing the same resources through both.

---

## Deploying to AWS (`dev`, `stg`, `prod`)

The current configuration is for MiniStack only. It must **not** be pointed at AWS as-is: the provider and S3 backend use `localhost:4566` and test credentials, and the website module grants public object reads. Treat the following as required work before any AWS deployment.

### Required configuration changes

1. **Create an AWS Terragrunt configuration path.** Prefer separate MiniStack and AWS root configs (for example, `root.ministack.hcl` and `root.aws.hcl`) so local endpoint settings cannot accidentally reach AWS. In the AWS provider, remove hard-coded `access_key`/`secret_key`, all `skip_*` flags, and the `endpoints` block. Use an AWS CLI SSO profile for local work or an IAM role/OIDC in CI, and pass a region per environment. Do not commit credentials.
2. **Use an AWS remote-state bucket.** Create the bucket outside the application stacks in the target account, enable versioning, encryption, and public-access blocking, and scope IAM access to the deployment role. Use a globally unique bucket name. Keep environment/stack state keys isolated; for production, consider a separate AWS account and state bucket. Enable S3 lock files (`use_lockfile = true`) and raise the Terraform minimum to `>= 1.10.0` if using that locking mechanism. Never reuse MiniStack state for AWS.
3. **Add the `stg` environment.** Create `terraform/live/stg/env.hcl` with `environment = "stg"` and copy the five stack `terragrunt.hcl` files from dev, retaining their module sources and dependency declarations. Update every environment validation in `terraform/environments/*/variables.tf` and `terraform/modules/*/variables.tf` to allow `stg` (or replace the hard-coded list with a documented environment policy). Add `stg` to the directory tree and CI checks. Set distinct state keys and review all resource names before applying.
4. **Make the website production-safe.** The current S3 website module disables public-access protections and allows `Principal = "*"`; it is only suitable for the local demo. For AWS production, keep the bucket private and serve it through CloudFront with Origin Access Control (OAC), TLS, and an appropriate DNS/certificate setup. If public S3 website hosting is deliberately retained for a non-production environment, make that behavior an explicit opt-in rather than a default.
5. **Review production controls.** Use separate AWS accounts or strong role boundaries for dev/stg/prod; define least-privilege deployment permissions; configure provider default tags; review SQS retention/visibility/redrive settings, SNS delivery/alarms, DynamoDB backups/PITR and encryption, and Secrets Manager rotation/access. Protect Terraform state because it can contain secret values, restrict access to plans/state, and do not print secrets in CI logs.
6. **Choose one source of truth.** `terraform/environments/{dev,prod}` are standalone roots with their own MiniStack provider configuration. Either retire them and deploy only through `terraform/live`, or update them to use the same AWS-safe provider/backend design; do not apply both paths to the same environment.

### Suggested AWS deployment flow

After implementing and reviewing the changes above, configure AWS SSO/role access and verify the active account and region before every deployment. Deploy environments separately, review plans, and apply only the reviewed plan:

```bash
aws sts get-caller-identity --profile tienda-dev
cd terraform/live/dev
terragrunt run --all plan
terragrunt run --all apply
```

Repeat with the appropriate profile and directory for `stg` and `prod`. Use production approvals in CI/CD, and do not run `terragrunt run --all apply` from `terraform/live` against AWS because that applies every environment in one operation.

### Current review notes

- `terraform fmt -check -recursive terraform` reports formatting needed in `terraform/modules/s3_website/main.tf`.
- HCL validation succeeds, with warnings that SNS receives mock SQS outputs when the dependency stack has not been applied.
- The documented MiniStack health URL (`/_localstack/health`) should be checked against the exact MiniStack image/version; it uses a LocalStack-style path.
- The project provisions foundational demo services, not a complete production commerce platform. Authentication, checkout/payment processing, application runtime, observability, backups, and a CDN/domain are outside the current modules.
