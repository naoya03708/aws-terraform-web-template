data "aws_region" "current" {}

# 最上段: SLO 達成状況（ユーザー体験）。下段: 原因調査用メトリクス（アラームにはしない）。
locals {
  lb = var.alb_arn_suffix

  m_requests = ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.lb, { id = "req", stat = "Sum", visible = false }]
  m_target5x = ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.lb, { id = "t5", stat = "Sum", visible = false }]
  m_elb5x    = ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.lb, { id = "e5", stat = "Sum", visible = false }]

  err_ratio = "(FILL(t5, 0) + FILL(e5, 0)) / (FILL(req, 0) + FILL(e5, 0))"
  budget    = format("%.6f", local.error_budget)
  region    = data.aws_region.current.region

  dashboard_widgets = [
    {
      type = "text", x = 0, y = 0, width = 24, height = 2
      properties = {
        markdown = "## SLO\n可用性 **${var.slo_availability_target * 100}%**（30日） / レイテンシ p95 **${var.slo_latency_threshold_seconds * 1000}ms** 未満。仮の SLO。定義とアラームの一次対応は docs/slo.md を参照。"
      }
    },
    {
      type = "metric", x = 0, y = 2, width = 8, height = 5
      properties = {
        title = "可用性（過去30日）", view = "singleValue", region = local.region
        start = "-P30D", end = "P0D", setPeriodToTimeRange = true
        metrics = [
          local.m_requests, local.m_target5x, local.m_elb5x,
          [{ expression = "100 * (1 - ${local.err_ratio})", label = "Availability % (SLO ${var.slo_availability_target * 100}%)", id = "avail" }],
        ]
      }
    },
    {
      type = "metric", x = 8, y = 2, width = 8, height = 5
      properties = {
        title = "エラーバジェット残量（過去30日）", view = "singleValue", region = local.region
        start = "-P30D", end = "P0D", setPeriodToTimeRange = true
        metrics = [
          local.m_requests, local.m_target5x, local.m_elb5x,
          [{ expression = "100 * (1 - (${local.err_ratio}) / ${local.budget})", label = "Error budget remaining %", id = "budget" }],
        ]
      }
    },
    {
      type = "metric", x = 16, y = 2, width = 8, height = 5
      properties = {
        title       = "レイテンシ p95（SLO ${var.slo_latency_threshold_seconds * 1000}ms）", view = "timeSeries", region = local.region, period = 300
        metrics     = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.lb, { stat = "p95", label = "p95" }]]
        annotations = { horizontal = [{ label = "SLO", value = var.slo_latency_threshold_seconds }] }
        yAxis       = { left = { min = 0 } }
      }
    },
    {
      type = "metric", x = 0, y = 7, width = 12, height = 6
      properties = {
        title = "エラーバジェット消費率（1h 窓。14.4=page / 6=ticket）", view = "timeSeries", region = local.region, period = 3600
        metrics = [
          local.m_requests, local.m_target5x, local.m_elb5x,
          [{ expression = "(${local.err_ratio}) / ${local.budget}", label = "Burn rate (1h)", id = "burn" }],
        ]
        annotations = { horizontal = [{ label = "fast (page)", value = 14.4 }, { label = "slow (ticket)", value = 6 }] }
        yAxis       = { left = { min = 0 } }
      }
    },
    {
      type = "metric", x = 12, y = 7, width = 12, height = 6
      properties = {
        title = "リクエスト数とエラー数", view = "timeSeries", region = local.region, period = 300, stat = "Sum"
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.lb, { label = "requests" }],
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.lb, { label = "target 5xx" }],
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", local.lb, { label = "elb 5xx" }],
        ]
      }
    },
    {
      type       = "text", x = 0, y = 13, width = 24, height = 1
      properties = { markdown = "## 原因調査用メトリクス（アラームなし）" }
    },
    {
      type = "metric", x = 0, y = 14, width = 8, height = 6
      properties = {
        title   = "正常ターゲット数", view = "timeSeries", region = local.region, period = 60, stat = "Minimum"
        metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", local.lb]]
      }
    },
    {
      type = "metric", x = 8, y = 14, width = 8, height = 6
      properties = {
        title = "ECS CPU / メモリ", view = "timeSeries", region = local.region, period = 60, stat = "Average"
        metrics = [
          ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
          ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
        ]
      }
    },
    {
      type = "metric", x = 16, y = 14, width = 8, height = 6
      properties = {
        title = "RDS CPU / 接続数 / 空き容量", view = "timeSeries", region = local.region, period = 60, stat = "Average"
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id, { yAxis = "right" }],
          ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_id, { yAxis = "right" }],
        ]
      }
    },
  ]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name
  dashboard_body = jsonencode({ widgets = local.dashboard_widgets })
}
