# dev: コスト優先の小規模構成
vpc_cidr           = "10.0.0.0/16"
az_count           = 2
single_nat_gateway = true

task_cpu           = 256
task_memory        = 512
desired_count      = 1
max_capacity       = 2
log_retention_days = 7

db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_multi_az              = false
db_backup_retention_days = 1

deletion_protection = false
enable_waf          = false

# HTTPS を有効化する場合のみ設定（ドメインと Route53 ホストゾーンが必要）
# domain_name     = "dev.example.com"
# route53_zone_id = "Z0123456789ABC"

# アラーム通知先（SNS メール購読。指定しない場合は購読を作成しない）
# alarm_email = "you@example.com"
