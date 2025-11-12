# ---------------------------
# Lambda Module Variables
# ---------------------------

variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "fetch_cloud_costs"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket where dashboard JSON is stored"
}

variable "ddb_table" {
  type        = string
  description = "DynamoDB table name to store AWS cost data"
}
