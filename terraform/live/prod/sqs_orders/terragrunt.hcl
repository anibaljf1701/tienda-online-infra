include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/sqs_orders"
}

dependency "sns_alerts" {
  config_path = "../sns_alerts"

  # Mock output used during `terragrunt validate` and `terragrunt plan`
  # when dependency outputs are not yet available.
  mock_outputs = {
    topic_arn = "arn:aws:sns:us-east-1:000000000000:mock-topic"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  sns_topic_arn = dependency.sns_alerts.outputs.topic_arn
}
