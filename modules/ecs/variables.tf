variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALB を配置するパブリックサブネット ID"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Fargate タスクを配置するプライベートサブネット ID"
  type        = list(string)
}

variable "container_image" {
  description = "コンテナイメージ"
  type        = string
}

variable "container_port" {
  description = "コンテナの待受ポート"
  type        = number
}

variable "health_check_path" {
  description = "ALB ヘルスチェックのパス"
  type        = string
  default     = "/"
}

variable "cpu" {
  description = "タスクの CPU ユニット"
  type        = number
}

variable "memory" {
  description = "タスクのメモリ(MiB)"
  type        = number
}

variable "desired_count" {
  description = "タスク数"
  type        = number
}

variable "log_retention_days" {
  description = "CloudWatch Logs の保持日数"
  type        = number
}

variable "deletion_protection" {
  description = "ALB の削除保護"
  type        = bool
  default     = false
}

variable "environment" {
  description = "コンテナへ渡す環境変数"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "コンテナへ注入する Secrets Manager シークレット（環境変数名 => ARN）"
  type        = map(string)
  default     = {}
}
