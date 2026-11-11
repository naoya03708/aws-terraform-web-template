# 0005. DB パスワードは RDS の Secrets Manager 管理にする

状態: Accepted

## 背景
DB のマスターパスワードを Terraform の変数やコードで扱うと、tfvars・state・ログに平文が残るリスクがある。

## 決定
- RDS の `manage_master_user_password = true` を使い、パスワードの生成・保管・ローテーションを RDS と Secrets Manager に任せる。
- ECS タスクには Secrets Manager の ARN を `secrets` として注入する（環境変数に平文を渡さない）。
- ECS の実行ロールには、注入するシークレット1件への `GetSecretValue` だけを許可する。

## 理由
- 人もコードもパスワードを知らずに済む。ローテーションにも対応できる。
- 最小権限で、シークレット単位に読み取りを絞れる。

## トレードオフ
- アプリはシークレットの JSON（`username` / `password`）をパースする必要がある。
- パスワードを人が直接知る運用（踏み台からの手動接続など）には、別途 IAM 認証や Secrets Manager 経由の取得手順が要る。
