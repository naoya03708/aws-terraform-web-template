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

variable "max_capacity" {
  description = "オートスケール時の最大タスク数（最小は desired_count）"
  type        = number
}

variable "cpu_target_utilization" {
  description = "オートスケールの CPU 使用率目標(%)"
  type        = number
  default     = 60
}

variable "domain_name" {
  description = "アプリの FQDN。指定すると ACM 証明書 + HTTPS を有効化する（null の場合は HTTP のみ）"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "domain_name を含む Route53 ホストゾーン ID（domain_name 指定時は必須）"
  type        = string
  default     = null

  validation {
    condition     = var.domain_name == null || var.route53_zone_id != null
    error_message = "domain_name を指定する場合は route53_zone_id も指定してください。"
  }
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
