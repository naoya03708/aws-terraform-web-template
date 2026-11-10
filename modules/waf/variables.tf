variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "alb_arn" {
  description = "WAF を関連付ける ALB の ARN"
  type        = string
}
