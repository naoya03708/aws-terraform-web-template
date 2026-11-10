variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB の ARN サフィックス（CloudWatch ディメンション）"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ターゲットグループの ARN サフィックス（ダッシュボード用）"
  type        = string
}

variable "cluster_name" {
  description = "ECS クラスター名（ダッシュボード用）"
  type        = string
}

variable "service_name" {
  description = "ECS サービス名（ダッシュボード用）"
  type        = string
}

variable "db_instance_id" {
  description = "RDS インスタンス識別子"
  type        = string
}

variable "db_allocated_storage_gib" {
  description = "RDS の割当ストレージ(GiB)。空き容量アラームの閾値算出に使う"
  type        = number
}

variable "slo_availability_target" {
  description = "可用性 SLO（例: 0.995 = 99.5%、30日間）"
  type        = number
  default     = 0.995

  validation {
    condition     = var.slo_availability_target > 0 && var.slo_availability_target < 1
    error_message = "slo_availability_target は 0 より大きく 1 未満で指定してください。"
  }
}

variable "slo_latency_threshold_seconds" {
  description = "レイテンシ SLO: リクエスト応答時間 p95 の上限(秒)"
  type        = number
  default     = 0.5
}

variable "min_requests_per_5m" {
  description = "5分あたりの最小リクエスト数。これ未満の窓はトラフィック不足としてアラーム評価しない（誤報防止）"
  type        = number
  default     = 10
}

variable "alarm_email" {
  description = "アラーム通知先メールアドレス（null の場合は購読を作成しない）"
  type        = string
  default     = null
}
