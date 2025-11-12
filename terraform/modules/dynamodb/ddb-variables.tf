##############################
# DynamoDB Module Variables
##############################

# Table name
variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table to store AWS cost data"
}

# Optional: read/write capacity mode
variable "read_capacity" {
  type        = number
  description = "Read capacity units (for provisioned mode)"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Write capacity units (for provisioned mode)"
  default     = 5
}

# Optional: billing mode (PAY_PER_REQUEST or PROVISIONED)
variable "billing_mode" {
  type        = string
  description = "Billing mode for DynamoDB table"
  default     = "PAY_PER_REQUEST"
}
