# Architecture Decision Records

設計上の判断と、その理由・トレードオフの記録です。決定を覆す場合は、既存の ADR を書き換えず新しい ADR を追加して「Superseded」にします。

| # | タイトル | 状態 |
| --- | --- | --- |
| [0001](0001-terragrunt-and-s3-native-lock.md) | state 管理に Terragrunt と S3 ネイティブロックを使う | Accepted |
| [0002](0002-trunk-based-development.md) | トランクベース開発とタグによる prod 昇格 | Accepted |
| [0003](0003-slo-based-alerting.md) | アラームは SLO（ユーザー体験）ベースにする | Accepted |
| [0004](0004-nat-gateway-per-environment.md) | NAT Gateway は dev で単一、prod で AZ ごと | Accepted |
| [0005](0005-secrets-manager-managed-db-password.md) | DB パスワードは RDS の Secrets Manager 管理にする | Accepted |
| [0006](0006-github-oidc-and-apply-role-scope.md) | GitHub OIDC で認証し、apply ロールの権限は割り切る | Accepted |
