# S3 bucket for static website hosting
resource "aws_s3_bucket" "main" {
  bucket = "${var.project}-${var.environment}-static"
}

# Website configuration: index and error documents
resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Allow public reads — required for MiniStack static website hosting
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy granting s3:GetObject to everyone (MiniStack local dev only)
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  # Depends on the public access block being removed first
  depends_on = [aws_s3_bucket_public_access_block.main]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

# Upload index.html rendered from a templatefile with environment, project, and products
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.main.id
  key          = "index.html"
  content      = templatefile("${path.module}/templates/index.html.tftpl", {
    environment = var.environment
    project     = var.project
    products    = local.seed_products
  })
  content_type = "text/html"
}

# Upload static error.html for 404 handling
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.main.id
  key          = "error.html"
  source       = "${path.module}/templates/error.html"
  content_type = "text/html"
}
