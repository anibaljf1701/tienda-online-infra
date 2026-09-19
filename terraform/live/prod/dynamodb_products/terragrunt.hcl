include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/dynamodb_products"
}

# No extra inputs needed — project and environment come from root inputs
