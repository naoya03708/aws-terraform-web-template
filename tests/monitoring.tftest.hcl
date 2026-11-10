mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

variables {
  name                     = "test"
  alb_arn_suffix           = "app/test-alb/0123456789abcdef"
  target_group_arn_suffix  = "targetgroup/app-1/0123456789abcdef"
  cluster_name             = "test"
  service_name             = "test"
  db_instance_id           = "test"
  db_allocated_storage_gib = 20
}

run "slo_burn_rate_alarms" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.burn) == 4
    error_message = "長窓・短窓 × fast/slow の4つのバーンレートアラームがあること"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.burn["fast_long"].threshold == 14.4 && aws_cloudwatch_metric_alarm.burn["slow_long"].threshold == 6
    error_message = "fast は 14.4 倍、slow は 6 倍の閾値であること"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.burn["fast_long"].treat_missing_data == "notBreaching"
    error_message = "データ欠損（無トラフィック）で誤報しないこと"
  }
}

run "notifications_routed_by_urgency" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = length(aws_cloudwatch_composite_alarm.burn_fast.alarm_actions) == 1 && length(aws_cloudwatch_composite_alarm.burn_slow.alarm_actions) == 1
    error_message = "複合アラームは通知先を持つこと（page / ticket）"
  }

  assert {
    condition     = try(length(aws_cloudwatch_metric_alarm.burn["fast_long"].alarm_actions), 0) == 0
    error_message = "個別の窓アラームは通知せず、複合アラーム経由でのみ通知すること"
  }

  assert {
    condition     = aws_sns_topic.page.name == "test-alerts-page" && aws_sns_topic.ticket.name == "test-alerts-ticket"
    error_message = "緊急用と業務時間内用で SNS トピックが分かれていること"
  }
}

run "no_subscription_without_email" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 0
    error_message = "alarm_email 未指定ではメール購読を作らないこと"
  }
}

run "subscriptions_with_email" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  variables {
    alarm_email = "ops@example.com"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 2
    error_message = "alarm_email 指定時は page / ticket 両方を購読すること"
  }
}

run "latency_slo_threshold" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  variables {
    slo_latency_threshold_seconds = 0.8
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.latency.threshold == 0.8
    error_message = "レイテンシ SLO の閾値が変数どおりであること"
  }
}

run "rejects_invalid_slo" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  variables {
    slo_availability_target = 1.5
  }

  expect_failures = [var.slo_availability_target]
}

run "rds_free_storage_is_only_cause_alarm" {
  command = plan

  module {
    source = "./modules/monitoring"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_free_storage.threshold == 20 * 0.15 * 1073741824
    error_message = "RDS 空き容量の閾値は割当の 15% であること"
  }
}
