output "secret_arn" {
  description = "ARN of the Secrets Manager secret. Verify with: aws --endpoint-url=http://localhost:4566 secretsmanager list-secrets"
  value       = aws_secretsmanager_secret.db_password.arn
}
