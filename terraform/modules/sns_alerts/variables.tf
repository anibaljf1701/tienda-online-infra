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

variable "sqs_queue_arn" {
  description = "ARN of the SQS orders queue to subscribe to this SNS topic"
  type        = string
}

variable "sqs_queue_url" {
  description = "URL of the SQS orders queue for the queue policy"
  type        = string
}
