output "page_topic_arn" {
  description = "即時対応（page）用 SNS トピック ARN"
  value       = aws_sns_topic.page.arn
}

output "ticket_topic_arn" {
  description = "業務時間内対応（ticket）用 SNS トピック ARN"
  value       = aws_sns_topic.ticket.arn
}

output "dashboard_name" {
  description = "CloudWatch ダッシュボード名"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
