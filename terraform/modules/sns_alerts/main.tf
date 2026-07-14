resource "aws_sns_topic" "main" {
  name = "${var.project}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}
