variable "name" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "cidr" {
  description = "VPC の CIDR（/16 を想定。サブネットは /24 で分割）"
  type        = string
}

variable "az_count" {
  description = "利用するAZ数"
  type        = number

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count は 2 または 3 を指定してください。"
  }
}

variable "single_nat_gateway" {
  description = "true の場合 NAT Gateway を1つに集約する"
  type        = bool
}
