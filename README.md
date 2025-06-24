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
# 全サービスのビルドと起動
docker-compose up --build -d

# スケールアウト（Jettyインスタンスを5つに増やす）
docker-compose up -d --scale spring-app=5
```

### 4. 動作確認

```bash
# ヘルスチェック
curl http://localhost/health

# 負荷分散の確認
for i in {1..10}; do curl http://localhost/api/instance; done
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

### Apache Benchを使用した例

```bash
# 1000リクエスト、同時接続数100
ab -n 1000 -c 100 http://localhost/api/test

# JMeterを使用した高度なテスト
./scripts/load-test.sh
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
docker-compose ps
docker-compose logs -f haproxy
docker-compose logs -f spring-app
```

### パフォーマンスの問題

- HAProxyの統計情報確認: `http://localhost:8404/stats`
- JVMヒープサイズの調整
- コネクションプールの設定確認

## 参考資料

- [HAProxy Documentation](http://www.haproxy.org/)
- [Spring Boot Reference](https://spring.io/projects/spring-boot)
- [Jetty Documentation](https://www.eclipse.org/jetty/documentation.php)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## ライセンス

MIT License
