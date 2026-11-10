output "alb_arn" {
  description = "ALB の ARN（WAF の関連付け用）"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ALB の ARN サフィックス（CloudWatch ディメンション用）"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ターゲットグループの ARN サフィックス（CloudWatch ディメンション用）"
  value       = aws_lb_target_group.this.arn_suffix
}

output "service_name" {
  description = "ECS サービス名"
  value       = aws_ecs_service.this.name
}

output "alb_dns_name" {
  description = "ALB の DNS 名"
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "アプリの URL（ドメイン指定時は HTTPS、未指定時は ALB への HTTP）"
  value       = local.enable_https ? "https://${var.domain_name}" : "http://${aws_lb.this.dns_name}"
}

output "cluster_name" {
  description = "ECS クラスター名"
  value       = aws_ecs_cluster.this.name
}

output "service_security_group_id" {
  description = "ECS サービスの Security Group ID（RDS の許可元）"
  value       = aws_security_group.service.id
}
