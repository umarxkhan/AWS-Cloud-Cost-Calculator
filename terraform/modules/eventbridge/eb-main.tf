# ---------------------------
# EventBridge Daily Trigger
# ---------------------------

# Schedule Lambda to run once a day
resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "daily_fetch_costs"
  schedule_expression = "rate(1 day)"
  description         = "Triggers Lambda daily to fetch AWS costs"
}

# Link EventBridge rule to Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_schedule.name
  target_id = "fetch_costs_lambda"
  arn       = var.lambda_arn
}

# Give EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}
