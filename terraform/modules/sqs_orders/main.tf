resource "aws_sqs_queue" "dlq" {
  name = "${var.project}-${var.environment}-orders-dlq"
}

resource "aws_sqs_queue" "main" {
  name = "${var.project}-${var.environment}-orders"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
