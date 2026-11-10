# Terragrunt ラッパー: state 用 S3 バケットの自動作成と、環境ごとの tfvars 切替を担う。
#
# 使い方:
#   ENV=dev  terragrunt plan     # dev.tfvars を使用（ENV 未指定時も dev）
#   ENV=prod terragrunt apply    # prod.tfvars を使用
#
# リージョンは AWS_REGION で上書き可能（既定: ap-northeast-1）。

locals {
  env        = get_env("ENV", "dev")
  region     = get_env("AWS_REGION", "ap-northeast-1")
  project    = "aws-tf-web"
  account_id = get_aws_account_id()
}

# S3 バケットが無ければ Terragrunt が作成する（バージョニング・暗号化・パブリックアクセスブロック有効）。
# ロックは S3 ネイティブロック（use_lockfile）。DynamoDB は不要。
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = "${local.project}-tfstate-${local.account_id}-${local.region}"
    key          = "${local.env}/terraform.tfstate"
    region       = local.region
    encrypt      = true
    use_lockfile = true
  }
}

terraform {
  extra_arguments "env_tfvars" {
    commands  = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=${get_terragrunt_dir()}/${local.env}.tfvars"]
  }
}

inputs = {
  project = local.project
  env     = local.env
  region  = local.region
}
# CI check
