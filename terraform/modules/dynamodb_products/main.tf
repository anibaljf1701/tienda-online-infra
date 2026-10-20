resource "aws_dynamodb_table" "main" {
  name         = "${var.project}-${var.environment}-products"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "seed" {
  for_each = local.seed_products

  table_name = aws_dynamodb_table.main.name
  hash_key   = aws_dynamodb_table.main.hash_key

  item = jsonencode({
    id    = { S = each.key }
    name  = { S = each.value.name }
    price = { N = tostring(each.value.price) }
    stock = { N = tostring(each.value.stock) }
  })
}
