include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3_website"
}

# No extra inputs needed — project, environment, region come from root inputs
