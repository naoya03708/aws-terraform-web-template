# 0001. state 管理に Terragrunt と S3 ネイティブロックを使う

状態: Accepted

## 背景
Terraform の state を S3 に置く場合、バケットとロック機構を事前に作る手間（鶏と卵問題）が発生する。テンプレートを clone してすぐ試せることを重視したい。

## 決定
- Terragrunt の `remote_state` で S3 バケットを自動作成する（バージョニング・暗号化有効）。
- ロックは S3 ネイティブロック（`use_lockfile = true`、Terraform 1.10+）を使い、DynamoDB は使わない。
- 環境は `ENV` 環境変数で切り替え、差分は直下の `dev.tfvars` / `prod.tfvars` で表現する。state の key は `<env>/terraform.tfstate`。

## 理由
- 事前作成の手順がなくなり、README の手順が短くなる。
- DynamoDB テーブルを管理対象から外せる。

## トレードオフ
- Terragrunt への依存が増える（CI・devcontainer にも導入が必要）。
- S3 ネイティブロックは比較的新しく、Terraform 1.10 未満では使えない（`required_version` で固定）。
- ディレクトリで環境を分ける構成より、環境間の state の誤操作は `ENV` の指定ミスに依存する。prod の apply は CI の承認ゲート経由に限定して緩和する（ADR 0002）。
