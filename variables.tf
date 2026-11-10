# --- Terragrunt の inputs から注入される値 ---
variable "project" {
  description = "プロジェクト名（リソース名のプレフィックス）"
  type        = string
}

variable "env" {
  description = "環境名（dev / prod）"
  type        = string
}

variable "region" {
  description = "AWS リージョン"
  type        = string
}

# --- ネットワーク ---
variable "vpc_cidr" {
  description = "VPC の CIDR"
  type        = string
}

variable "az_count" {
  description = "利用するAZ数"
  type        = number
}

variable "single_nat_gateway" {
  description = "true の場合 NAT Gateway を1つに集約（コスト削減。本番は false 推奨）"
  type        = bool
}

# --- ECS ---
variable "container_image" {
  description = "デプロイするコンテナイメージ"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "コンテナの待受ポート"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB ヘルスチェックのパス"
  type        = string
  default     = "/"
}

variable "task_cpu" {
  description = "Fargate タスクの CPU ユニット"
  type        = number
}

variable "task_memory" {
  description = "Fargate タスクのメモリ(MiB)"
  type        = number
}

variable "desired_count" {
  description = "ECS サービスのタスク数"
  type        = number
}

variable "max_capacity" {
  description = "オートスケール時の最大タスク数（最小は desired_count）"
  type        = number
}

variable "domain_name" {
  description = "アプリの FQDN。指定すると ACM + HTTPS を有効化（null は HTTP のみ）"
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "domain_name を含む Route53 ホストゾーン ID（domain_name 指定時は必須）"
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "ALB に AWS マネージドルールの WAF を関連付けるか"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs の保持日数"
  type        = number
}

# --- RDS ---
variable "db_name" {
  description = "初期作成するデータベース名"
  type        = string
  default     = "app"
}

variable "db_engine_version" {
  description = "PostgreSQL のバージョン"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS インスタンスクラス"
  type        = string
}

variable "db_allocated_storage" {
  description = "RDS ストレージ容量(GiB)"
  type        = number
}

variable "db_multi_az" {
  description = "RDS を Multi-AZ 構成にするか"
  type        = bool
}

variable "db_backup_retention_days" {
  description = "RDS 自動バックアップの保持日数"
  type        = number
}

# --- 監視 (SLO) ---
variable "slo_availability_target" {
  description = "可用性 SLO（0.995 = 99.5%、30日間）。サンプルアプリ用の仮値"
  type        = number
  default     = 0.995
}

variable "slo_latency_threshold_seconds" {
  description = "レイテンシ SLO: 応答時間 p95 の上限(秒)。サンプルアプリ用の仮値"
  type        = number
  default     = 0.5
}

variable "alarm_email" {
  description = "アラーム通知先メールアドレス（null の場合は購読を作成しない）"
  type        = string
  default     = null
}

# --- 共通 ---
variable "deletion_protection" {
  description = "ALB / RDS の削除保護（本番は true）"
  type        = bool
}
