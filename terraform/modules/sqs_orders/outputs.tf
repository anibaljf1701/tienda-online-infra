output "queue_url" {
  description = "Main SQS orders queue URL. Verify: aws --endpoint-url=http://localhost:4566 sqs list-queues"
  value       = aws_sqs_queue.main.id
}

output "queue_arn" {
  description = "Main SQS orders queue ARN. Verify: aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes --queue-url <queue_url> --attribute-names QueueArn"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "Dead-letter queue URL. Verify: aws --endpoint-url=http://localhost:4566 sqs list-queues"
  value       = aws_sqs_queue.dlq.id
}
