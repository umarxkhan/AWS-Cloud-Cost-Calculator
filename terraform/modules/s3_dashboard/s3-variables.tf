variable "bucket_name" {
  description = "Name of the S3 bucket for dashboard"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "Dev"
}

# Optional: price class for CloudFront distributions
variable "price_class" {
  description = "CloudFront price class (e.g., PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

# Optional: origin ID for CloudFront
variable "s3_origin_id" {
  description = "Origin ID for S3 in CloudFront"
  type        = string
  default     = "s3-dashboard-origin"
}

# Optional: tags for CloudFront or other resources
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
