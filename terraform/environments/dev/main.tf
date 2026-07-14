module "sqs_orders" {
  source        = "../../modules/sqs_orders"
  project       = var.project
  environment   = var.environment
  sns_topic_arn = module.sns_alerts.topic_arn
}

module "sns_alerts" {
  source        = "../../modules/sns_alerts"
  project       = var.project
  environment   = var.environment
  sqs_queue_arn = module.sqs_orders.queue_arn
}

module "s3_website" {
  source      = "../../modules/s3_website"
  project     = var.project
  environment = var.environment
  region      = var.region
}

module "dynamodb_products" {
  source      = "../../modules/dynamodb_products"
  project     = var.project
  environment = var.environment
}

module "secrets" {
  source      = "../../modules/secrets"
  project     = var.project
  environment = var.environment
}
