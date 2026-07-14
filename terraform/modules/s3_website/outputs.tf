output "bucket_name" {
  description = "Name of the S3 static website bucket. Verify with: aws --endpoint-url=http://localhost:4566 s3 ls"
  value       = aws_s3_bucket.main.bucket
}

output "website_endpoint" {
  description = "Static website endpoint URL. Verify with: aws --endpoint-url=http://localhost:4566 s3api get-bucket-website --bucket <bucket_name>"
  value       = aws_s3_bucket_website_configuration.main.website_endpoint
}
