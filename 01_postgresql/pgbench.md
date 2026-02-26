# [pgbench](https://www.postgresql.org/docs/current/pgbench.html)

## インストール

```sh
# amazonlinux2
sudo amazon-linux-extras install postgresql11
sudo yum install postgresql-contrib
```

## 初期化

```sh
# 基本
pgbench -i -h ホスト名 -p ポート番号 -U ユーザー名 -d データベース名
# スケーリングファクター数を調整
## スケーリングファクター数は1あたり、１０万件のデータ量(テーブル名:pgbench_accounts)があるので、数値が高いほど扱うデータ量が増え、負荷を高めたテストが可能
pgbench -i -h ホスト名 -p ポート番号 -U ユーザー名 -d データベース名 -s 2(スケーリングファクター数。デフォルトは1)
```

## 確認

```sh
# 基本
pgbench -h ホスト名 -U ユーザー名 -p ポート番号 -d データベース名 -T 300(テストしたい期間秒数) -c 10(想定クライアント数)

# スケーリングファクターを調整
pgbench -h ホスト名 -U ユーザー名 -p ポート番号 -d データベース名 -T 300(テストしたい期間秒数) -c 10(想定クライアント数) -s 10(スケーリングファクター)

# スレッド数を調整
pgbench -h ホスト名 -U ユーザー名 -p ポート番号 -d データベース名 -T 300(テストしたい期間秒数) -c 10(想定クライアント数) -j 2(スレッド数)

# select文のみ
pgbench -h ホスト名 -U ユーザー名 -p ポート番号 -d データベース名 -T 300(テストしたい期間秒数) -c 10(想定クライアント数) -S
```

## 後片付け

```psql
DROP TABLE IF EXISTS pgbench_accounts, pgbench_branches, pgbench_tellers, pgbench_history;
```

## 結果の見方

```sh
transaction type: <builtin: TPC-B (sort of)>            #   使用されたトランザクションのタイプ
scaling factor: 1                                       #   スケーリングファクター(テストデータの量を調整するための指標)
query mode: simple                                      #   クエリのモード
number of clients: 10                                   #   テスト実行時のクライアント数
number of threads: 1                                    #   使用されたスレッド数
duration: 300 s                                         #   テストが実行された期間（秒単位）
number of transactions actually processed: 99999        #   実際に処理されたトランザクション数
latency average = 11.111 ms                             #   平均レイテンシ（遅延時間/ミリ秒単位）
tps = 111.111111 (including connections establishing)   #   秒間トランザクション数（TPS/接続確立を含む場合の値)
tps = 111.222222 (excluding connections establishing)   #   秒間トランザクション数（TPS/接続確立を除いた場合の値）
```
