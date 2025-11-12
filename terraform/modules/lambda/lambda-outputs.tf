# ---------------------------
# Lambda Module Outputs
# ---------------------------

output "fetch_costs_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.fetch_costs.arn
}

output "fetch_costs_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.fetch_costs.function_name
}
