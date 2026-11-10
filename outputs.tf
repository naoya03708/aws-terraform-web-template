output "alb_dns_name" {
  description = "ALB の DNS 名（HTTP でアクセス可能）"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS クラスター名"
  value       = module.ecs.cluster_name
}

output "db_endpoint" {
  description = "RDS エンドポイント"
  value       = module.rds.endpoint
}

output "db_master_secret_arn" {
  description = "RDS マスター認証情報の Secrets Manager ARN"
  value       = module.rds.master_user_secret_arn
}
