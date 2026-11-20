# コスト試算

`ap-northeast-1`、730時間/月、トラフィック・ログ量は最小の想定での**概算**です。単価は公表価格を基にした目安で、私が最新単価を確認したものではありません。見積もりや契約の根拠にする前に、[AWS Pricing Calculator](https://calculator.aws/) または infracost で再確認してください。

## 月額の目安

| 項目 | dev | prod | 前提 |
| --- | ---: | ---: | --- |
| NAT Gateway | $45 | $136 | $0.062/h。dev は1台、prod は AZ ごと3台（データ処理料は除く） |
| ALB | $24 | $24 | $0.0243/h + LCU 最小 1 想定 |
| ECS Fargate | $11 | $45 | dev: 0.25vCPU/0.5GB×1、prod: 0.5vCPU/1GB×2（常時最小数） |
| RDS PostgreSQL | $22 | $90 | dev: t4g.micro 単一AZ + 20GB、prod: t4g.small Multi-AZ + 50GB（gp3） |
| Public IPv4 | $11 | $22 | $0.005/h。ALB（AZ数）+ NAT の EIP |
| WAF | - | $9 | Web ACL $5 + ルール3×$1 + リクエスト課金は僅少と想定 |
| その他 | $7 | $7 | Secrets Manager、KMS、ダッシュボード、アラーム、ログ |
| **合計** | **約 $120** | **約 $330** | |

dev を検証のために立ち上げる場合は、**1日あたり約 $4**（約 600 円）です。検証後は必ず `ENV=dev terragrunt destroy` で削除します。

## コストの大きい項目と削減余地

- **NAT Gateway が最大**: dev は1台に集約済み。S3 ゲートウェイエンドポイント（無料）で ECR レイヤ取得が NAT を通らないため、データ処理料も抑えている。さらに削るなら、ECR / Secrets Manager / CloudWatch Logs 用の VPC エンドポイント（インターフェース型は 1 つ約 $7/月/AZ）と比較検討する。
- **Public IPv4 課金**: ALB と NAT の分は避けにくい。
- **RDS**: dev は停止してもストレージ課金が残る。使わない期間は destroy が確実。
- **Fargate Spot / Savings Plans**: prod が安定したら検討。

## 実績との突き合わせ

dev を実環境（`ap-southeast-2`）に1回 apply → destroy して検証しました（[README の検証状況](../README.md#検証状況)）。

| 項目 | 値 |
| --- | --- |
| 実績（請求に反映された消費額） | **約 $1.82** |
| 稼働時間 | 半日前後（apply 完了から destroy 開始までの正確な時間は記録していない） |
| 概算（上の表、dev 約 $4/日）での同じ時間の目安 | 約 $2 前後 |

この1回の検証では、概算と実績は、同じ桁で一致しました。ただし、次の点があるため、精度の裏付けとしては粗いものです。

- 稼働時間を正確に測っておらず、内訳（NAT、ALB、RDS など）も確認していません。
- 上の表の単価は `ap-northeast-1` の目安で、検証したのは `ap-southeast-2` です。リージョンによって単価は異なります。
- 検証の間、トラフィックはほぼ無く、データ処理料などの従量部分はほとんど発生していません。

本番（prod）の費用は、実環境で確認していません。
