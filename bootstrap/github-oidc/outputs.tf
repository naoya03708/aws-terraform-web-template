output "plan_role_arn" {
  description = "リポジトリ変数 AWS_PLAN_ROLE_ARN に設定する値"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "リポジトリ変数 AWS_APPLY_ROLE_ARN に設定する値"
  value       = aws_iam_role.apply.arn
}
