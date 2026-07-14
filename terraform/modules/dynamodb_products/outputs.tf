output "table_name" {
  description = "DynamoDB products table name. Verify: aws --endpoint-url=http://localhost:4566 dynamodb list-tables"
  value       = aws_dynamodb_table.main.name
}

output "table_arn" {
  description = "DynamoDB products table ARN. Verify: aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name <table_name>"
  value       = aws_dynamodb_table.main.arn
}
