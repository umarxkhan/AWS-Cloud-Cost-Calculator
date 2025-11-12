##############################
# DynamoDB Module Outputs
##############################

output "table_name" {
  description = "Name of the DynamoDB table storing AWS cost data"
  value       = aws_dynamodb_table.costs_table.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.costs_table.arn
}
