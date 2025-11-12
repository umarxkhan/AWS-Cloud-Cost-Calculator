provider "aws" {
  region = var.region
}

module "s3_dashboard" {
  source      = "./modules/s3_dashboard"
  bucket_name = var.s3_bucket_name
  region      = var.region
}

module "cloudfront_acm" {
  source = "./modules/cloudfront-acm"

  bucket_name                 = module.s3_dashboard.bucket_name
  bucket_regional_domain_name = module.s3_dashboard.bucket_regional_domain_name
  bucket_arn                  = module.s3_dashboard.bucket_arn
  s3_origin_id                = "s3-dashboard-origin" # internal identifier
  domain_name                 = var.domain_name
  price_class                 = var.price_class
  tags                        = var.tags
}

module "lambda" {
  source         = "./modules/lambda"
  lambda_name    = var.lambda_name
  s3_bucket_name = var.s3_bucket_name
  ddb_table      = var.ddb_table
}

module "eventbridge" {
  source      = "./modules/eventbridge"
  lambda_arn  = module.lambda.fetch_costs_arn
  lambda_name = module.lambda.fetch_costs_name
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = var.ddb_table
}

##############################
# CloudFront Cache Invalidation
# Purpose: Clears the CloudFront cache automatically after Terraform applies
# Why: Ensures that updated files (dashboard, JS, CSS) are served immediately
##############################

resource "null_resource" "invalidate_cloudfront" {
  # Triggers force this resource to run when the CloudFront distribution changes
  # or when the last_update timestamp changes (every apply)
  triggers = {
    distribution_id = module.cloudfront_acm.distribution_id
    last_update     = timestamp() # forces invalidation on every apply
  }

  # local-exec provisioner runs a shell command on your machine
  provisioner "local-exec" {
    command = <<EOT
      # Create a CloudFront invalidation for all paths
      aws cloudfront create-invalidation \
        --distribution-id ${module.cloudfront_acm.distribution_id} \
        --paths "/*"
    EOT
  }
}

