##############################
# Lambda Module
# Purpose: Create IAM role, attach policy, and deploy Lambda function
##############################

# ---------------------------
# 1. ZIP Packaging of Lambda Code
# ---------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/fetch_costs.py"
  output_path = "${path.module}/../../../lambda/fetch_costs.zip"
}

# ---------------------------
# 2. IAM Role for Lambda
# ---------------------------
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}_role"

  # Trust policy allowing AWS Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# ---------------------------
# 3. IAM Inline Policy
# ---------------------------
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_name}_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage", # Access AWS Cost Explorer
          "dynamodb:PutItem",   # Store cost data
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "s3:PutObject", # Update dashboard JSON
          "s3:GetObject",
          "logs:CreateLogGroup", # CloudWatch Logs
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*" # Can restrict to specific ARNs
      }
    ]
  })
}

# ---------------------------
# 4. Lambda Function
# ---------------------------
resource "aws_lambda_function" "fetch_costs" {
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "fetch_costs.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60

  # Use automatically packaged ZIP file
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  # Environment variables accessible inside Lambda
  environment {
    variables = {
      DDB_TABLE      = var.ddb_table
      S3_BUCKET_NAME = var.s3_bucket_name # Must match Python code
    }
  }

  tags = {
    Project = "CloudCostCalculator"
  }
}
