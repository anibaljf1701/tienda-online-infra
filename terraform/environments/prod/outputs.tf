output "website_bucket_name" {
  description = "Name of the S3 static website bucket. Verify: aws --endpoint-url=http://localhost:4566 s3 ls"
  value       = module.s3_website.bucket_name
}

output "website_endpoint" {
  description = "Static website endpoint URL. Verify: aws --endpoint-url=http://localhost:4566 s3api get-bucket-website --bucket <bucket_name>"
  value       = module.s3_website.website_endpoint
}

output "sqs_queue_url" {
  description = "Main SQS orders queue URL. Verify: aws --endpoint-url=http://localhost:4566 sqs list-queues"
  value       = module.sqs_orders.queue_url
}

output "sqs_queue_arn" {
  description = "Main SQS orders queue ARN. Verify: aws --endpoint-url=http://localhost:4566 sqs get-queue-attributes --queue-url <queue_url> --attribute-names QueueArn"
  value       = module.sqs_orders.queue_arn
}

output "sqs_dlq_url" {
  description = "Dead-letter queue URL. Verify: aws --endpoint-url=http://localhost:4566 sqs list-queues"
  value       = module.sqs_orders.dlq_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic. Verify: aws --endpoint-url=http://localhost:4566 sns list-topics"
  value       = module.sns_alerts.topic_arn
}

output "dynamodb_table_name" {
  description = "DynamoDB products table name. Verify: aws --endpoint-url=http://localhost:4566 dynamodb list-tables"
  value       = module.dynamodb_products.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB products table ARN. Verify: aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name <table_name>"
  value       = module.dynamodb_products.table_arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager db_password secret. Verify: aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets"
  value       = module.secrets.secret_arn
}
