output "endpoint" {
  description = "RDS エンドポイント（host:port）"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS ホスト名"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS ポート"
  value       = aws_db_instance.this.port
}

output "master_user_secret_arn" {
  description = "マスター認証情報の Secrets Manager ARN"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
