# practice-java-ha-proxy

## 概要

このリポジトリは、Java Spring、HAProxy、JettyをDocker Composeで構成し、大量のリクエストを効率的に処理するシステムの構築と理解を目的としています。ロードバランシング、スケーラビリティ、高可用性について実践的に学ぶことができます。

## システムアーキテクチャ

```
                    ┌─────────────┐
                    │   Client    │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │   HAProxy   │
                    │(Port: 80)   │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐┌──────▼──────┐┌──────▼──────┐
     │  Jetty-1    ││  Jetty-2    ││  Jetty-3    │
     │(Port: 8081) ││(Port: 8082) ││(Port: 8083) │
     │             ││             ││             │
     │Spring Boot  ││Spring Boot  ││Spring Boot  │
     │    App      ││    App      ││    App      │
     └─────────────┘└─────────────┘└─────────────┘
```

## ディレクトリ構成

```
practice-java-ha-proxy/
├── README.md
├── docker-compose.yml          # Docker Compose設定ファイル
├── .env.example               # 環境変数の例
├── .gitignore
│
├── spring-app/                # Spring Bootアプリケーション
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/example/haproxy/
│   │   │   │       ├── Application.java
│   │   │   │       ├── controller/
│   │   │   │       ├── service/
│   │   │   │       └── config/
│   │   │   └── resources/
│   │   │       ├── application.yml
│   │   │       └── application-prod.yml
│   │   └── test/
│   ├── pom.xml               # Maven設定（または build.gradle）
│   └── Dockerfile
│
├── haproxy/                  # HAProxy設定
│   ├── haproxy.cfg          # HAProxy設定ファイル
│   └── Dockerfile
│
├── jetty/                    # Jetty設定（必要に応じて）
│   └── jetty.xml
│
├── scripts/                  # ユーティリティスクリプト
│   ├── load-test.sh         # 負荷テストスクリプト
│   ├── health-check.sh      # ヘルスチェックスクリプト
│   └── deploy.sh            # デプロイスクリプト
│
├── monitoring/               # モニタリング設定
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── dashboards/
│
└── docs/                    # ドキュメント
    ├── architecture.md      # アーキテクチャ詳細
    ├── performance.md       # パフォーマンステスト結果
    └── troubleshooting.md   # トラブルシューティング
```

## 必要な環境

- Docker Desktop 20.10以上
- Docker Compose 2.0以上
- Java 11以上（開発時）
- Maven 3.6以上（開発時）

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-username/practice-java-ha-proxy.git
cd practice-java-ha-proxy
```

### 2. 環境変数の設定

```bash
cp .env.example .env
# 必要に応じて.envファイルを編集
```

### 3. アプリケーションのビルドと起動

```bash
# 方法1: deployスクリプトを使用（推奨）
./scripts/deploy.sh up

# 方法2: Docker Composeを直接使用
docker-compose up --build -d

# モニタリング付きで起動
./scripts/deploy.sh up --monitoring
```

### 4. 動作確認

```bash
# ヘルスチェックスクリプトの実行
./scripts/health-check.sh

# または個別に確認
# APIエンドポイントの確認
curl http://localhost/api/test

# インスタンス情報の確認
curl http://localhost/api/instance | jq

# 負荷分散の確認（異なるインスタンスIDが返される）
for i in 1 2 3; do 
  echo "Request $i:"
  curl -s http://localhost/api/instance | jq -r .instanceId
done
```

## 利用可能なエンドポイント

### アプリケーションAPI

- `GET /api/instance` - インスタンス情報を取得
- `GET /api/test` - テストエンドポイント（リクエストカウント付き）
- `POST /api/heavy?iterations=5000` - 重い処理のシミュレーション
- `GET /api/metrics/custom` - カスタムメトリクスの取得

### ヘルスチェック・メトリクス

- `GET /actuator/health` - ヘルスチェック
- `GET /actuator/info` - アプリケーション情報
- `GET /actuator/metrics` - メトリクス一覧
- `GET /actuator/prometheus` - Prometheus形式のメトリクス

### 管理インターフェース

- HAProxy統計情報: http://localhost:8404/stats
  - ユーザー名: admin
  - パスワード: admin

## 運用操作

### スケーリング

```bash
# 5インスタンスにスケールアウト
./scripts/deploy.sh scale --instances 5

# または直接Docker Composeで
docker-compose up -d --scale spring-app=5
```

### ログの確認

```bash
# すべてのログを確認
./scripts/deploy.sh logs --follow

# 特定のサービスのログ
docker-compose logs -f haproxy
docker-compose logs -f spring-app
```

### システムステータス

```bash
# 全体のステータス確認
./scripts/deploy.sh status

# リソース使用状況
docker stats
```

### 停止・再起動

```bash
# 停止
./scripts/deploy.sh down

# 再起動
./scripts/deploy.sh restart

# 完全なクリーンアップ
./scripts/deploy.sh clean
```

## 主な機能

### Spring Bootアプリケーション
- RESTful API エンドポイント
- データベース接続（オプション）
- セッション管理
- メトリクス収集

### HAProxy設定
- ラウンドロビン負荷分散
- ヘルスチェック
- セッション永続性（必要に応じて）
- SSL/TLS終端（オプション）

### モニタリング
- Prometheus + Grafana（オプション）
- アプリケーションメトリクス
- システムメトリクス

## 負荷テスト

### 負荷テストスクリプトの使用

```bash
# デフォルト設定で実行（10000リクエスト、同時接続数100）
./scripts/load-test.sh

# カスタム設定で実行
./scripts/load-test.sh --requests 5000 --concurrency 50

# 特定のエンドポイントをテスト
./scripts/load-test.sh --endpoint /api/heavy --requests 100

# ヘルプの表示
./scripts/load-test.sh --help
```

### Apache Benchを直接使用

```bash
# 基本的な負荷テスト
ab -n 1000 -c 100 http://localhost/api/test

# POSTリクエストの負荷テスト
ab -n 100 -c 10 -p post_data.txt -T application/json http://localhost/api/heavy?iterations=1000

# 詳細な統計情報付き
ab -n 1000 -c 100 -g results.tsv http://localhost/api/test
```

### 負荷テスト結果の確認

```bash
# HAProxy統計情報でリアルタイム確認
open http://localhost:8404/stats

# コンテナのリソース使用状況
docker stats

# アプリケーションのカスタムメトリクス
curl http://localhost/api/metrics/custom | jq
```

## 設定のカスタマイズ

### HAProxyの設定変更

`haproxy/haproxy.cfg`を編集して、負荷分散アルゴリズムやヘルスチェック間隔を調整できます。

### Jettyインスタンス数の変更

```bash
# 10インスタンスで起動
docker-compose up -d --scale spring-app=10
```

### アプリケーションの設定

`spring-app/src/main/resources/application.yml`で、ポート番号やデータベース接続などを設定できます。

## トラブルシューティング

### コンテナの状態確認

```bash
# 全コンテナの状態
docker-compose ps

# 特定のサービスのログ確認
docker-compose logs --tail=50 haproxy
docker-compose logs --tail=50 spring-app

# リアルタイムログ監視
docker-compose logs -f
```

### よくある問題と解決方法

#### HAProxyが起動しない

```bash
# エラーログの確認
docker-compose logs haproxy | grep ERROR

# 設定ファイルの構文チェック
docker run --rm -v $(pwd)/haproxy:/usr/local/etc/haproxy:ro haproxy:2.8-alpine haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg

# よくある原因：設定ファイルの最終行に改行がない場合
echo >> haproxy/haproxy.cfg
```

#### Spring Bootアプリケーションが起動しない

```bash
# Javaのメモリ不足の場合
# docker-compose.ymlでJAVA_OPTSを調整
JAVA_OPTS=-Xmx1g -Xms512m

# ポート競合の確認
lsof -i :8080
```

#### 負荷分散が機能しない

```bash
# ヘルスチェックの状態確認
curl -u admin:admin http://localhost:8404/stats | grep "web_servers"

# 個別インスタンスへの直接アクセステスト
docker exec practice-java-ha-proxy-spring-app-1 curl -s localhost:8080/actuator/health
```

### パフォーマンスの問題

- HAProxyの統計情報確認: `http://localhost:8404/stats`
- JVMヒープサイズの調整
- コネクションプールの設定確認

### デバッグモード

```bash
# HAProxyのデバッグモード起動
docker-compose exec haproxy haproxy -d

# Spring Bootのデバッグログ有効化
# application.ymlで設定
logging:
  level:
    com.example.haproxy: DEBUG
```

## 参考資料

- [HAProxy Documentation](http://www.haproxy.org/)
- [Spring Boot Reference](https://spring.io/projects/spring-boot)
- [Jetty Documentation](https://www.eclipse.org/jetty/documentation.php)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## ライセンス

MIT License
