variable "project" {
  description = "Project name prefix used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic allowed to send messages to the SQS queue"
  type        = string
}
