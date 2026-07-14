output "topic_arn" {
  description = "ARN of the SNS alerts topic. Verify with: aws --endpoint-url=http://localhost:4566 sns list-topics"
  value       = aws_sns_topic.main.arn
}
