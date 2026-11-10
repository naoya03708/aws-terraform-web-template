provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

locals {
  name = "${var.project}-${var.env}"
}

module "vpc" {
  source = "./modules/vpc"

  name               = local.name
  cidr               = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
}

module "ecs" {
  source = "./modules/ecs"

  name                = local.name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  container_image     = var.container_image
  container_port      = var.container_port
  health_check_path   = var.health_check_path
  cpu                 = var.task_cpu
  memory              = var.task_memory
  desired_count       = var.desired_count
  max_capacity        = var.max_capacity
  log_retention_days  = var.log_retention_days
  deletion_protection = var.deletion_protection
  domain_name         = var.domain_name
  route53_zone_id     = var.route53_zone_id

  environment = {
    DB_HOST = module.rds.address
    DB_PORT = tostring(module.rds.port)
    DB_NAME = var.db_name
  }

  # RDS が Secrets Manager で管理するマスター認証情報（JSON）をコンテナへ注入
  secrets = {
    DB_CREDENTIALS = module.rds.master_user_secret_arn
  }
}

# 未完成機能と同様に enable_waf = false のままマージできる（トランクベース）
module "waf" {
  count  = var.enable_waf ? 1 : 0
  source = "./modules/waf"

  name    = local.name
  alb_arn = module.ecs.alb_arn
}

module "rds" {
  source = "./modules/rds"

  name                  = local.name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  allowed_sg_id         = module.ecs.service_security_group_id
  db_name               = var.db_name
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.deletion_protection
}
