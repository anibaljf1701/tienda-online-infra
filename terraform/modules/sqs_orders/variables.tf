variable "project" {
  description = "Project name prefix used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be 'dev', 'stg', or 'prod'."
  }
}
