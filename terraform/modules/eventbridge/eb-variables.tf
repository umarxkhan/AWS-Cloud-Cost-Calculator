# Lambda function ARN to trigger
variable "lambda_arn" {
  type        = string
  description = "ARN of the Lambda function to trigger"
}

# Lambda function name (needed for permission)
variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function to trigger"
}
