variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "DB サブネットグループに含めるプライベートサブネット ID"
  type        = list(string)
}

variable "allowed_sg_id" {
  description = "DB への接続を許可する Security Group ID"
  type        = string
}

variable "db_name" {
  description = "初期データベース名"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL のバージョン"
  type        = string
}

variable "instance_class" {
  description = "インスタンスクラス"
  type        = string
}

variable "allocated_storage" {
  description = "ストレージ容量(GiB)"
  type        = number
}

variable "multi_az" {
  description = "Multi-AZ 構成にするか"
  type        = bool
}

variable "backup_retention_days" {
  description = "自動バックアップの保持日数"
  type        = number
}

variable "deletion_protection" {
  description = "削除保護。false の場合は最終スナップショットを作成しない"
  type        = bool
}
