# GitHub Actions -> AWS の OIDC 連携（長期アクセスキー不要）。
# 一度だけ、管理者権限でローカルから apply する（state はローカル。詳細は README 参照）。

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-tf-web"
      ManagedBy = "terraform"
      Component = "github-oidc-bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  repo = var.github_repository
  # Terragrunt が自動作成する state バケット（terragrunt.hcl の命名規則と一致させる）
  state_bucket_arn = "arn:aws:s3:::aws-tf-web-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# --- plan 用: 読み取り専用 + state の読み書き（ロックファイル用）。PR から利用 ---
data "aws_iam_policy_document" "plan_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repo}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "github-actions-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "state-access"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

# --- apply 用: GitHub Environment (dev / prod) 経由のジョブのみ引き受け可能 ---
# prod は Environment 側で「タグ v* のみ」「必須レビュアー」を設定する（README 参照）。
data "aws_iam_policy_document" "apply_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repo}:environment:dev",
        "repo:${local.repo}:environment:prod",
      ]
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = "github-actions-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

# ネットワーク/ECS/RDS/IAM/ALB など幅広いサービスを作成するため、デモ用途では AdministratorAccess。
# 信頼条件を Environment に限定することでリスクを抑えている。実運用では権限境界や
# サービス別ポリシーへの絞り込みを推奨（docs/adr で言及予定）。
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
