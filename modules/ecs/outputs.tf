output "alb_dns_name" {
  description = "ALB の DNS 名"
  value       = aws_lb.this.dns_name
}

output "cluster_name" {
  description = "ECS クラスター名"
  value       = aws_ecs_cluster.this.name
}

output "service_security_group_id" {
  description = "ECS サービスの Security Group ID（RDS の許可元）"
  value       = aws_security_group.service.id
}
