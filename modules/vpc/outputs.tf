output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "パブリックサブネット ID（ALB 配置用）"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "プライベートサブネット ID（ECS / RDS 配置用）"
  value       = aws_subnet.private[*].id
}
