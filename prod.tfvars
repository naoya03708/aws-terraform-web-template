# prod: 可用性・保護を優先した構成
vpc_cidr           = "10.1.0.0/16"
az_count           = 3
single_nat_gateway = false

task_cpu           = 512
task_memory        = 1024
desired_count      = 2
log_retention_days = 30

db_instance_class        = "db.t4g.small"
db_allocated_storage     = 50
db_multi_az              = true
db_backup_retention_days = 7

deletion_protection = true
