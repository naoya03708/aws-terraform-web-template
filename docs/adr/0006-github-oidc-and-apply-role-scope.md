# 0006. GitHub OIDC で認証し、apply ロールの権限は割り切る

状態: Accepted

## 背景
CI から AWS を操作するために、長期のアクセスキーを GitHub Secrets に置くと、漏洩時の影響が大きく、ローテーションも手間になる。

## 決定
- GitHub Actions の OIDC で一時認証情報を取得する。長期キーは使わない。
- ロールを2つに分ける。
  - **plan 用**: `ReadOnlyAccess` + state バケットの読み書き（ロックファイル用）。信頼条件は `pull_request` のみ。fork からの PR には権限を渡さない。
  - **apply 用**: GitHub Environment（`dev` / `prod`）経由のジョブのみ引き受け可能。権限は `AdministratorAccess`。
- prod は Environment の必須レビュアーと「タグ `v*` のみ」のデプロイ制限で守る。

## 理由
- 一時認証情報なので、キーの漏洩・保管の問題がない。
- plan（レビュー前に誰でも走る）と apply（承認後のみ）で権限を分離できる。

## トレードオフ（割り切り）
- apply ロールは VPC・ECS・RDS・IAM・WAF・KMS など広範なサービスを作るため、デモ用途では `AdministratorAccess` にしている。**実運用ではサービス別ポリシーや権限境界（permissions boundary）への絞り込みを推奨する。** 引き受け条件を Environment に限定することでリスクを抑えている。
- OIDC プロバイダと IAM ロールは別ルートモジュール（`bootstrap/github-oidc`）で、初回のみ管理者がローカルから apply する必要がある。
