include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/sns_alerts"
}

dependency "sqs_orders" {
  config_path = "../sqs_orders"

  # Mock output used during `terragrunt validate` and `terragrunt plan`
  # when dependency outputs are not yet available.
  mock_outputs = {
    queue_arn = "arn:aws:sqs:us-east-1:000000000000:mock-queue"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  sqs_queue_arn = dependency.sqs_orders.outputs.queue_arn
}
