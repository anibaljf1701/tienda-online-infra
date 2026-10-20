include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/sns_alerts"
}

dependency "sqs_orders" {
  config_path = "../sqs_orders"

  mock_outputs = {
    queue_arn = "arn:aws:sqs:us-east-1:000000000000:mock-queue"
    queue_url = "http://localhost:4566/000000000000/mock-queue"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  sqs_queue_arn = dependency.sqs_orders.outputs.queue_arn
  sqs_queue_url = dependency.sqs_orders.outputs.queue_url
}