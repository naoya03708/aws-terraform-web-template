mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name               = "test"
  vpc_id             = "vpc-12345678"
  public_subnet_ids  = ["subnet-a", "subnet-b"]
  private_subnet_ids = ["subnet-c", "subnet-d"]
  container_image    = "public.ecr.aws/nginx/nginx:stable"
  container_port     = 80
  cpu                = 256
  memory             = 512
  desired_count      = 2
  max_capacity       = 6
  log_retention_days = 7
}

run "http_only_without_domain" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 0 && length(aws_acm_certificate.this) == 0
    error_message = "domain_name 未指定では HTTPS リスナー/証明書を作らないこと"
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "forward"
    error_message = "domain_name 未指定では HTTP リスナーは直接転送すること"
  }
}

run "https_with_domain" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  variables {
    domain_name     = "app.example.com"
    route53_zone_id = "Z0123456789ABC"
  }

  assert {
    condition     = length(aws_lb_listener.https) == 1 && length(aws_acm_certificate.this) == 1
    error_message = "domain_name 指定時は HTTPS リスナーと ACM 証明書を作ること"
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "redirect"
    error_message = "HTTPS 有効時は HTTP を 443 へリダイレクトすること"
  }
}

run "domain_requires_zone" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  variables {
    domain_name = "app.example.com"
  }

  expect_failures = [var.route53_zone_id]
}

run "autoscaling_bounds" {
  command = plan

  module {
    source = "./modules/ecs"
  }

  assert {
    condition     = aws_appautoscaling_target.this.min_capacity == 2 && aws_appautoscaling_target.this.max_capacity == 6
    error_message = "オートスケールの最小は desired_count、最大は max_capacity であること"
  }
}
