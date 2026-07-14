# WARNING: This provider configuration is for LOCAL development only.
# Points all AWS service calls to MiniStack (http://localhost:4566).
# DO NOT use in any cloud environment. Remove the endpoints block for cloud deployments.

provider "aws" {
  region     = var.region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  default_tags {
    tags = local.common_tags
  }

  endpoints {
    s3             = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
    lambda         = "http://localhost:4566"
  }
}
