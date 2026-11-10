output "web_acl_arn" {
  description = "WAF Web ACL の ARN"
  value       = aws_wafv2_web_acl.this.arn
}
