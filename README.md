# Tienda Online Infrastructure

Terraform infrastructure for a local online store demo using **MiniStack** (local AWS emulator on `localhost:4566`). Provisions S3 static website hosting, SQS order queues, SNS alerts, DynamoDB products table, and Secrets Manager — all isolated per environment.

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

Each environment (`dev`, `prod`) has its own isolated set of all resources above. No resources are shared between environments.

---

## Prerequisites

- **Docker** with MiniStack running on port `4566`
- **Terraform** >= 1.6.0
- **AWS CLI** configured for local use (endpoint override `http://localhost:4566`)

Verify MiniStack is up before applying:

```bash
docker ps | grep ministack
```

---

## Directory Structure

```
tienda_online/
├── .gitignore
├── README.md
└── terraform/
    ├── environments/
    │   ├── dev/
    │   │   ├── versions.tf
    │   │   ├── providers.tf
    │   │   ├── variables.tf
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   ├── locals.tf
    │   │   └── terraform.tfvars
    │   └── prod/
    │       ├── versions.tf
    │       ├── providers.tf
    │       ├── variables.tf
    │       ├── main.tf
    │       ├── outputs.tf
    │       ├── locals.tf
    │       └── terraform.tfvars
    └── modules/
        ├── s3_website/
        │   ├── versions.tf
        │   ├── variables.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── locals.tf
        ├── sqs_orders/
        │   ├── versions.tf
        │   ├── variables.tf
        │   ├── main.tf
        │   └── outputs.tf
        ├── sns_alerts/
        │   ├── versions.tf
        │   ├── variables.tf
        │   ├── main.tf
        │   └── outputs.tf
        ├── dynamodb_products/
        │   ├── versions.tf
        │   ├── variables.tf
        │   ├── main.tf
        │   ├── outputs.tf
        │   └── locals.tf
        └── secrets/
            ├── versions.tf
            ├── variables.tf
            ├── main.tf
            └── outputs.tf
```

---

## Local Workflow

```bash
# 1. Confirm MiniStack is running
docker ps | grep ministack

# 2. Deploy dev environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# 3. Deploy prod environment
cd ../prod
terraform init
terraform plan
terraform apply
```

---

## Terraform Outputs

### Dev environment

| Output | Verification command |
|--------|----------------------|
| `website_bucket_name` | `aws --endpoint-url=http://localhost:4566 s3 ls` |
| `website_endpoint` | `aws --endpoint-url=http://localhost:4566 s3api get-bucket-website --bucket tienda-dev-static` |
| `sqs_queue_url` | `aws --endpoint-url=http://localhost:4566 sqs list-queues` |
| `sqs_queue_arn` | `aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes --queue-url <url> --attribute-names QueueArn` |
| `sqs_dlq_url` | `aws --endpoint-url=http://localhost:4566 sqs list-queues` |
| `sns_topic_arn` | `aws --endpoint-url=http://localhost:4566 sns list-topics` |
| `dynamodb_table_name` | `aws --endpoint-url=http://localhost:4566 dynamodb list-tables` |
| `dynamodb_table_arn` | `aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name tienda-dev-products` |
| `secret_arn` | `aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets` |

Replace `dev` with `prod` in the commands above when verifying the prod environment.

---

## Browse the Static Website

After `terraform apply`, the static product catalog is available directly via MiniStack:

```
http://localhost:4566/tienda-dev-static/index.html
http://localhost:4566/tienda-prod-static/index.html
```

Open either URL in a browser. The page header shows an environment badge (`DEV` or `PROD`) so you can tell them apart at a glance.

---

## Query the DynamoDB Products Table

```bash
aws --endpoint-url=http://localhost:4566 dynamodb scan \
  --table-name tienda-dev-products
```

Swap `tienda-dev-products` for `tienda-prod-products` to query the prod table.

---

## Dev vs Prod Differences

The only difference between the two environments is the `terraform.tfvars` file in each directory:

- `terraform/environments/dev/terraform.tfvars` sets `environment = "dev"`
- `terraform/environments/prod/terraform.tfvars` sets `environment = "prod"`

That single value propagates automatically to all resource names (e.g., `tienda-dev-static` vs `tienda-prod-static`), tags, and outputs. No `.tf` files need to be duplicated or modified between environments.
