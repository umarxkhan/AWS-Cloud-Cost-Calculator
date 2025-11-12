variable "bucket_name" {
  description = "Name of the S3 bucket to serve as CloudFront origin"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket to use as CloudFront origin"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "s3_origin_id" {
  description = "Origin ID for the S3 bucket in CloudFront"
  type        = string
  default     = "s3-dashboard-origin"
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class (controls which edge locations are used)"
  type        = string
  default     = "PriceClass_200"
}

variable "tags" {
  description = "Tags to apply to CloudFront resources"
  type        = map(string)
  default     = {}
}
