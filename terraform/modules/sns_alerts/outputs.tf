output "topic_arn" {
  description = "ARN of the SNS alerts topic. Verify: aws --profile local sns list-topics"
  value       = aws_sns_topic.main.arn
}
