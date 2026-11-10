mock_provider "aws" {}

run "dev_no_final_snapshot" {
  command = plan

  module {
    source = "./modules/rds"
  }

  variables {
    name                  = "test"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-1", "subnet-2"]
    allowed_sg_id         = "sg-12345678"
    db_name               = "app"
    engine_version        = "16"
    instance_class        = "db.t4g.micro"
    allocated_storage     = 20
    multi_az              = false
    backup_retention_days = 1
    deletion_protection   = false
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == true
    error_message = "削除保護なし(dev)では最終スナップショットを作成しないこと"
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false && aws_db_instance.this.storage_encrypted == true
    error_message = "RDS は非公開かつ暗号化されていること"
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "マスターパスワードは Secrets Manager 管理であること"
  }
}

run "prod_protected" {
  command = plan

  module {
    source = "./modules/rds"
  }

  variables {
    name                  = "test"
    vpc_id                = "vpc-12345678"
    subnet_ids            = ["subnet-1", "subnet-2"]
    allowed_sg_id         = "sg-12345678"
    db_name               = "app"
    engine_version        = "16"
    instance_class        = "db.t4g.small"
    allocated_storage     = 50
    multi_az              = true
    backup_retention_days = 7
    deletion_protection   = true
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == true && aws_db_instance.this.skip_final_snapshot == false
    error_message = "本番は削除保護あり・最終スナップショットありであること"
  }

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "本番は Multi-AZ であること"
  }
}
