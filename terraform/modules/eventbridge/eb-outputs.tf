output "event_rule_name" {
  description = "Name of the EventBridge rule triggering Lambda"
  value       = aws_cloudwatch_event_rule.daily_schedule.name
}
