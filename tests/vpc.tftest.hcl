mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
    }
  }
}

run "dev_single_nat" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name               = "test"
    cidr               = "10.0.0.0/16"
    az_count           = 2
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "az_count 分のパブリック/プライベートサブネットが作成されること"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway=true では NAT Gateway は1つであること"
  }

  assert {
    condition     = aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway"
    error_message = "S3 ゲートウェイエンドポイントが作成されること"
  }
}

run "prod_nat_per_az" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name               = "test"
    cidr               = "10.1.0.0/16"
    az_count           = 3
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "single_nat_gateway=false では AZ ごとに NAT Gateway が作成されること"
  }

  assert {
    condition     = length(aws_route_table.private) == 3
    error_message = "プライベートルートテーブルが AZ ごとに作成されること"
  }
}

run "rejects_invalid_az_count" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name               = "test"
    cidr               = "10.0.0.0/16"
    az_count           = 1
    single_nat_gateway = true
  }

  expect_failures = [var.az_count]
}
