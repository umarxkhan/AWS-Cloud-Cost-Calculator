##############################
# DynamoDB Module
# Purpose: Create table to store AWS cost data
##############################

resource "aws_dynamodb_table" "costs_table" {
  name         = var.table_name
  billing_mode = var.billing_mode

  # Primary key: date (string) to store daily cost records
  hash_key = "record_date"

  attribute {
    name = "record_date"
    type = "S" # String
  }

  tags = {
    Project = "CloudCostCalculator"
  }
}
