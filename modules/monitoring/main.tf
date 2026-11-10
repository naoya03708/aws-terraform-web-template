# ユーザー体験（SLO/SLI）ベースの監視。
# 鳴らすのは「ユーザーが困っているか」だけ。CPU/メモリ等の原因系メトリクスはダッシュボード表示のみ。
# 例外として、ユーザー影響が出る前に対処が必要な RDS 空き容量だけは原因系でもアラームにする。
# 詳細は docs/slo.md を参照。

data "aws_caller_identity" "current" {}

locals {
  error_budget = 1 - var.slo_availability_target

  # multi-window multi-burn-rate（Google SRE Workbook）。長窓と短窓の両方が超過した時だけ通知する。
  #   fast: 14.4 倍 = 30日バジェットの 2% を 1 時間で消費するペース -> 即時対応（page）
  #   slow:  6.0 倍 = 30日バジェットの 5% を 6 時間で消費するペース -> チケット
  burn_windows = {
    fast_long  = { period = 3600, threshold = 14.4 }
    fast_short = { period = 300, threshold = 14.4 }
    slow_long  = { period = 21600, threshold = 6 }
    slow_short = { period = 1800, threshold = 6 }
  }

  lb_dimensions = { LoadBalancer = var.alb_arn_suffix }
}

# --- 通知 (SNS)。page = 即時対応、ticket = 業務時間内対応 ---
resource "aws_kms_key" "sns" {
  description         = "${var.name} alarm notifications"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        # CloudWatch Alarms が暗号化済みトピックへ発行できるようにする
        Sid       = "AllowCloudWatchAndSns"
        Effect    = "Allow"
        Principal = { Service = ["cloudwatch.amazonaws.com", "sns.amazonaws.com"] }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey*"]
        Resource  = "*"
        Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
      },
    ]
  })
}

resource "aws_sns_topic" "page" {
  name              = "${var.name}-alerts-page"
  kms_master_key_id = aws_kms_key.sns.arn
}

resource "aws_sns_topic" "ticket" {
  name              = "${var.name}-alerts-ticket"
  kms_master_key_id = aws_kms_key.sns.arn
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.alarm_email != null ? { page = aws_sns_topic.page.arn, ticket = aws_sns_topic.ticket.arn } : {}

  topic_arn = each.value
  protocol  = "email"
  endpoint  = var.alarm_email
}

# --- SLI 1: 可用性（エラーバジェット消費率）---
# 可用性 SLI = 1 - エラー数 / 総リクエスト数
#   エラー数 = ターゲットの 5xx + ALB 自身の 5xx（全ターゲット停止時の 503 など）
#   総数     = RequestCount + ALB 自身の 5xx（ターゲットに到達しなかった要求も含める）
# 消費率 = (エラー率) / (1 - SLO)。1.0 で 30 日ちょうどバジェットを使い切るペース。
resource "aws_cloudwatch_metric_alarm" "burn" {
  for_each = local.burn_windows

  alarm_name          = "${var.name}-slo-burn-${replace(each.key, "_", "-")}"
  alarm_description   = "可用性SLOのエラーバジェット消費率が ${each.value.threshold} 倍以上（窓: ${each.value.period / 60} 分）。単体では通知せず、複合アラームで長窓・短窓を AND する。"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "requests"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = local.lb_dimensions
    }
  }

  metric_query {
    id          = "target5xx"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = local.lb_dimensions
    }
  }

  metric_query {
    id          = "elb5xx"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      period      = each.value.period
      stat        = "Sum"
      dimensions  = local.lb_dimensions
    }
  }

  metric_query {
    id          = "total"
    expression  = "FILL(requests, 0) + FILL(elb5xx, 0)"
    return_data = false
  }

  metric_query {
    id          = "errors"
    expression  = "FILL(target5xx, 0) + FILL(elb5xx, 0)"
    return_data = false
  }

  # トラフィックが少なすぎる窓は評価しない（数件のエラーで誤報になるのを防ぐ）
  metric_query {
    id          = "burn"
    label       = "Error budget burn rate"
    expression  = "IF(total < ${var.min_requests_per_5m * each.value.period / 300}, 0, (errors / total) / ${format("%.6f", local.error_budget)})"
    return_data = true
  }
}

# 急速消費: 1h かつ 5m の両方が 14.4 倍以上 -> page
resource "aws_cloudwatch_composite_alarm" "burn_fast" {
  alarm_name        = "${var.name}-slo-availability-fast-burn"
  alarm_description = "可用性SLOのバジェットを急速に消費中（直近1時間・5分とも 14.4 倍以上）。ユーザーが今エラーを受けている。docs/slo.md の一次対応を参照。"
  alarm_rule        = "ALARM(\"${aws_cloudwatch_metric_alarm.burn["fast_long"].alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.burn["fast_short"].alarm_name}\")"
  alarm_actions     = [aws_sns_topic.page.arn]
  ok_actions        = [aws_sns_topic.page.arn]
}

# 緩やかな消費: 6h かつ 30m の両方が 6 倍以上 -> ticket
resource "aws_cloudwatch_composite_alarm" "burn_slow" {
  alarm_name        = "${var.name}-slo-availability-slow-burn"
  alarm_description = "可用性SLOのバジェットを継続的に消費中（直近6時間・30分とも 6 倍以上）。放置すると月内にバジェットを使い切る。docs/slo.md の一次対応を参照。"
  alarm_rule        = "ALARM(\"${aws_cloudwatch_metric_alarm.burn["slow_long"].alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.burn["slow_short"].alarm_name}\")"
  alarm_actions     = [aws_sns_topic.ticket.arn]
  ok_actions        = [aws_sns_topic.ticket.arn]
}

# --- SLI 2: レイテンシ（p95 が SLO 閾値を超過し続けている）---
# ALB は「閾値以内のリクエスト数」を出さないため、p95 の閾値比較で近似する（簡略化。docs/slo.md 参照）。
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${var.name}-slo-latency-p95"
  alarm_description   = "応答時間 p95 が ${var.slo_latency_threshold_seconds} 秒を 30 分間（6 窓中 5 窓）超過。docs/slo.md の一次対応を参照。"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.slo_latency_threshold_seconds
  evaluation_periods  = 6
  datapoints_to_alarm = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ticket.arn]
  ok_actions          = [aws_sns_topic.ticket.arn]

  metric_query {
    id          = "requests"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 300
      stat        = "Sum"
      dimensions  = local.lb_dimensions
    }
  }

  metric_query {
    id          = "p95"
    return_data = false

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      period      = 300
      stat        = "p95"
      dimensions  = local.lb_dimensions
    }
  }

  metric_query {
    id          = "latency"
    label       = "Target response time p95"
    expression  = "IF(requests < ${var.min_requests_per_5m}, 0, p95)"
    return_data = true
  }
}

# --- 唯一の原因系アラーム: RDS 空き容量 ---
# ストレージ枯渇は発生するとユーザー影響が即座に深刻化し、SLO アラームでは間に合わないため例外とする。
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.name}-rds-free-storage-low"
  alarm_description   = "RDS の空き容量が割当の 15% を下回った（枯渇するとユーザー影響が出る前に対処が必要）。"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.db_instance_id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = var.db_allocated_storage_gib * 0.15 * 1073741824
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ticket.arn]
  ok_actions          = [aws_sns_topic.ticket.arn]
}
