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

# --- 共通 ---
variable "deletion_protection" {
  description = "ALB / RDS の削除保護（本番は true）"
  type        = bool
}
