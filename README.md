# aws-terraform-web-template

AWS 上の標準的な Web アプリ基盤（VPC / ALB / ECS Fargate / RDS PostgreSQL）を、Terraform + Terragrunt でコード化したテンプレートです。dev / prod の環境差分は tfvars だけで表現し、state 用 S3 バケットの事前作成は不要です。

## 構成図

```mermaid
flowchart LR
  user([Internet]) --> alb
  subgraph vpc[VPC]
    subgraph pub[Public Subnets]
      alb[ALB]
      nat[NAT Gateway]
    end
    subgraph pri[Private Subnets]
      ecs[ECS Fargate Service]
      rds[(RDS PostgreSQL)]
    end
  end
  alb -->|HTTP| ecs
  ecs -->|5432| rds
  ecs -.->|image pull / Secrets Manager| nat
  rds -.->|master password| sm[(Secrets Manager)]
```

## ディレクトリ構成

```text
.
├── main.tf / variables.tf / outputs.tf / versions.tf   # ルートモジュール（modules を呼び出す）
├── terragrunt.hcl        # state バックエンド自動作成 + 環境別 tfvars の切替
├── dev.tfvars            # dev 環境の差分（小規模・単一NAT・削除保護なし）
├── prod.tfvars           # prod 環境の差分（マルチAZ・NAT冗長・削除保護あり）
├── modules/
│   ├── vpc/              # VPC / Subnet / IGW / NAT / Route Table
│   ├── ecs/              # ALB / ECS Fargate / IAM 実行ロール / CloudWatch Logs
│   └── rds/              # RDS PostgreSQL / Subnet Group / Security Group
├── .devcontainer/        # terraform, terragrunt, tflint, aws cli, gh, git 入りの開発環境
└── .github/workflows/    # PR 時の静的チェック
```

## 設計思想

- **最小権限**: Security Group は `Internet → ALB → ECS → RDS` の参照連鎖のみ許可。RDS は ECS の SG からの 5432 だけ受け付け、パブリックアクセス不可。VPC のデフォルト SG は全ルール削除。ECS の実行ロールは注入するシークレットの読み取りのみ追加許可。
- **機密情報をコードに置かない**: RDS のマスターパスワードは `manage_master_user_password` により Secrets Manager で管理し、ECS タスクへ Secrets として注入。
- **再利用性**: コンポーネントごとに `modules/` 化。環境差分は `dev.tfvars` / `prod.tfvars` のみで、ディレクトリを複製しない。
- **state 管理**: Terragrunt の `remote_state` が S3 バケット（バージョニング・暗号化有効）を自動作成。ロックは S3 ネイティブロック（`use_lockfile`、Terraform 1.10+）で、DynamoDB は不要。state キーは `<env>/terraform.tfstate` で環境ごとに分離。

## 使い方

### 1. 開発環境の起動

VS Code で開き、Dev Containers で「Reopen in Container」。terraform / terragrunt / tflint / aws cli / gh / git が利用できます。

```bash
gh auth login          # 必要に応じて
aws configure sso      # もしくは aws configure
export AWS_PROFILE=<your-profile>
```

### 2. 実行

環境は環境変数 `ENV`（既定 `dev`）で切り替えます。

```bash
ENV=dev  terragrunt plan
ENV=dev  terragrunt apply
ENV=prod terragrunt plan
```

初回実行時、`aws-tf-web-tfstate-<account_id>-<region>` バケットが無ければ Terragrunt が作成します。リージョンは `AWS_REGION` で変更できます（既定 `ap-northeast-1`）。

> ⚠️ `apply` すると NAT Gateway / ALB / RDS など課金されるリソースが作成されます。検証後は `ENV=dev terragrunt destroy` で削除してください。

### 3. 注意点

- ALB は HTTP(80) のみです。本番利用時は ACM 証明書 + HTTPS リスナーを追加してください。
- 既定のコンテナイメージは `public.ecr.aws/nginx/nginx:stable` です。`container_image` を変更してアプリに差し替えます。

## CI/CD

`.github/workflows/terraform-ci.yml` が Pull Request 時に以下を実行します（AWS 認証不要）。

| チェック | 内容 |
| --- | --- |
| `terraform fmt -check -recursive` | フォーマット |
| `terragrunt hcl fmt --check` | `terragrunt.hcl` のフォーマット |
| `terraform validate` | 構文・整合性（`init -backend=false`） |
| `tflint` | 静的解析（terraform / aws ルールセット） |

結果は PR コメントに集約表示され（再実行時は同コメントを更新）、いずれか失敗すると CI が失敗します。

## 今後の予定

- GCP 版（`gcp-terraform-web-template`: Cloud Run / Cloud SQL）の追加
