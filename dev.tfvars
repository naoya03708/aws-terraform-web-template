# dev: コスト優先の小規模構成
vpc_cidr           = "10.0.0.0/16"
az_count           = 2
single_nat_gateway = true

task_cpu           = 256
task_memory        = 512
desired_count      = 1
log_retention_days = 7

db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_multi_az              = false
db_backup_retention_days = 1

deletion_protection = false
