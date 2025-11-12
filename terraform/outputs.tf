output "bucket_name" {
  value = module.s3_dashboard.bucket_name
}

output "cloudfront_url" {
  value       = "https://${module.cloudfront_acm.cloudfront_domain}"
  description = "Public URL of the site via CloudFront"
}

# Lambda function ARN and name
output "lambda_arn" {
  value       = module.lambda.fetch_costs_arn
  description = "ARN of the deployed Lambda function"
}

output "lambda_name" {
  value       = module.lambda.fetch_costs_name
  description = "Name of the deployed Lambda function"
}

# DynamoDB table name
output "ddb_table_name" {
  value       = module.dynamodb.table_name
  description = "Name of the DynamoDB table storing cost data"
}

