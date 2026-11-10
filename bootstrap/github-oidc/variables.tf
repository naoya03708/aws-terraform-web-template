variable "region" {
  description = "AWS リージョン（ルートモジュールの AWS_REGION と揃える）"
  type        = string
  default     = "ap-northeast-1"
}

variable "github_repository" {
  description = "OIDC を許可する GitHub リポジトリ（owner/repo）"
  type        = string
  default     = "naoya03708/aws-terraform-web-template"
}
