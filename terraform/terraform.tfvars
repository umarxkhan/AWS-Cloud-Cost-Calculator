s3_bucket_name = "my-cloud-cost-dashboard"
region         = "eu-central-1"
domain_name    = "my-cloud-cost-dashboard"
lambda_name    = "fetch_cloud_costs"
ddb_table      = "cloud_costs"
price_class    = "PriceClass_100"
tags = {
  Project = "CloudCostCalculator"
}
