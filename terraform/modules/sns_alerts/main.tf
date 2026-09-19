# SNS topic
resource "aws_sns_topic" "main" {
  name = "${var.project}-${var.environment}-alerts"
}

# Subscribe the SQS queue to this topic
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = var.sqs_queue_arn
}

# Allow this SNS topic to send messages to the SQS queue
resource "aws_sqs_queue_policy" "orders" {
  queue_url = var.sqs_queue_url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = var.sqs_queue_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.main.arn
          }
        }
      }
    ]
  })
}
