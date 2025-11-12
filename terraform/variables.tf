variable "s3_bucket_name" {
  description = "S3 bucket for the dashboard"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Custom domain (e.g., mubarak.khan.cloud1.engineer)"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200"
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "fetch_cloud_costs"
}

variable "ddb_table" {
  type        = string
  description = "DynamoDB table name to store AWS cost data"
}