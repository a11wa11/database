# postgresql

- [postgresql](#postgresql)
  - [コマンド](#コマンド)
    - [接続](#接続)
    - [確認系](#確認系)
    - [便利系](#便利系)
    - [function](#function)
    - [index](#index)
    - [調査](#調査)
    - [拡張機能](#拡張機能)
    - [dump](#dump)
    - [リストア](#リストア)
    - [メンテナンス・パフォーマンス改善](#メンテナンスパフォーマンス改善)
    - [論理レプリケーション](#論理レプリケーション)
    - [プライマリキー関連](#プライマリキー関連)
  - [pgbenchを使って測定](#pgbenchを使って測定)

## コマンド

### 接続

```sh
# 基本
psql -h ホスト名 -U ユーザー名 -p 5432 -d データベース名
psql "host=ホスト名 port=5432 dbname=データベース名 user=ユーザー名 sslmode=require"

# ファイル実行(-aでコメントも出力する)
psql -a -h ホスト名 -U ユーザー名 -p 5432 -d データベース名 < ファイル名.sql

# データベース切替
\c データベース名
```

- ヘルスチェック

```sh
pg_isready -h ホスト名 -U ユーザー名

>ホスト名:5432 - accepting connections
```


### 確認系

```sql
-- データベース
\l (show databases;)

-- テーブル
\d (show tables;)

-- テーブルのカラム名
\d+ テーブル名;

-- スキーマ
\dn

-- スキーマに所属するテーブル一覧
\d スキーマ名.*

-- ユーザー権限
\du

-- インデックス一覧
\di

-- データベース切替
\c データベース名
\connect データベース名

-- ユーザー一覧
select * from pg_user;

-- タイムゾーン
show timezone;

-- 現在時間
select now();

-- バージョン
select version();

--ディスク容量
SELECT pg_size_pretty(pg_database_size('データベース名'));
SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;

--インデックス一覧
SELECT * FROM pg_indexes;

--データが多いテーブルを知りたい(行数目安)
SELECT
  schemaname,
  relname AS table_name,
  n_live_tup AS approx_rows
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC
LIMIT 10;

--テーブルサイズ順(インデックス込)
SELECT
  schemaname AS schema,
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

### 便利系

```sql
-- 見やすく縦表示の切替
\x
select * from テーブル名;

-- ページャーをlessに変更
--- 表示中に-N と押下すると最下部に「Constantly display line numbers (press RETURN)」と表示されるのでRETURNキー押下で行番号表示が可能。再度で行番号表示消去
\setenv PAGER less

-- pagerのON/OFF切替
\pset pager

-- 実行時間を表示する
\timing

-- バックグラウンド実行
SELECT * FROM my_table \gexec

-- タイムアウト値変更
set statement_timeout = '10min';  #10分
set statement_timeout = '300s';   #300秒(5分)

-- メタコマンド シェルなど外部コマンドをpsql接続中に実施する
\! ls -l
```

### function

```sql
-- INTERSECT演算子で複数のSELECT結果の共通部分を取得
SELECT カラムA FROM テーブルA
INTERSECT
SELECT カラムB FROM テーブルB;
```

### index

```sql
# インデックス作成
create index on テーブル名 (カラム名);
CREATE INDEX IF NOT EXISTS インデックス名 ON テーブル名 (カラム名); -- 存在しない場合のみ

# インデックス削除
DROP INDEX インデックス名;
DROP INDEX IF EXISTS インデックス名; -- 存在する場合のみ

# インデックスはデフォルトではB-treeなのでB-tree以外で作成する場合
CREATE INDEX インデックス名 ON テーブル名 USING gist (カラム名) -- gistで作成の場合
```

### 調査

- pg_stat_activityビューに含まれる主な列は以下の通り

| 項目名 | 説明 |
|-|-|
| datid | データベースのOID（識別子） |
| datname | データベース名 |
| pid | プロセスID（セッションID） |
| usename | 接続ユーザー名 |
| client_addr | クライアントのIPアドレス |
| client_hostname | クライアントのホスト名 |
| query | 実行中のクエリ |
| state | セッションの状態（例 active, idle, idle in transactionなど） |
| wait_event_type | セッションが待機しているイベントの種類 |
| wait_event | セッションが待機している具体的なイベント |
| backend_start | バックエンドプロセスの開始時刻 |
| backend_type | バックエンドプロセスのタイプ（例: client backend, autovacuum launcherなど） |

```sql
-- 現在実行中のセッション（プロセス）に関する情報を取得
SELECT * FROM pg_stat_activity;

-- 準備済みトランザクション（Prepared Transaction）の数をカウントする
SELECT count(*) FROM pg_catalog.pg_prepared_xacts;

-- プライマリキーなど制約を確認
SELECT * FROM information_schema.table_constraints;

-- インストール可能な拡張機能を確認する
SELECT * FROM pg_available_extensions;

-- 現在のデータベースにインストールされているすべての拡張機能の情報を取得
SELECT * FROM pg_extension;

-- タイムアウト値確認
show statement_timeout;

-- 指定テーブルのカラム確認
select * from information_schema.columns where table_name='テーブル名' order by ordinal_position;
```

- [explainコマンド](https://postgresweb.com/post-4047)で調査

 ```sql
-- 推定された実行計画を表示する
explain select * from テーブル名;

-- 実際に実行した結果を表示する
explain analyze select * from テーブル名; 
```

### 拡張機能

```sql
-- 指定拡張機能アップグレードコマンド  
ALTER EXTENSION 拡張機能名 UPDATE TO '新バージョン';

-- インストール済拡張機能でデフォルトバージョンより低いものを抽出
SELECT * FROM pg_available_extensions WHERE default_version > installed_version;
```

### dump

```sh
# データベース全体dump
pg_dump -h ホスト名 -U ユーザー名 -p 5432 -d データベース名 > backup_file名
# テーブル指定(複数)
pg_dump -h ホスト名 -U ユーザー名 -p 5432 -d データベース名 -t テーブル1 -t テーブル2 -t テーブル3 > backup_file名
# バイナリ形式でdump保存 -F=ファイル形式 c=ファイル形式をPostgresqlのバイナリ形式
pg_dump -Fc -f ファイル名.dump -h ホスト名 -d データベース名 -U ユーザー名
```

### リストア

pg_restoreでバイナリファイル形式のバックファイルからのリストアの方が確実

```sh
pg_restore -h ホスト名 -C -d データベース名 バックアップファイル名
psql -h ホスト名 -U ユーザー名 -d データベース名 -f バックアップファイル名
psql "host=ホスト名 port=5432 dbname=データベース名 user=ユーザー名 sslmode=require" --file=バックアップファイル名

# 特定のテーブルのみを指定する場合
pg_restore -h ホスト名 -C -d データベース名 -t テーブル名 バックアップファイル名
psql -h ホスト名 -U ユーザー名 -d データベース名 -t テーブル名1,テーブル名2,テーブル名3 -f バックアップファイル名
```

### メンテナンス・パフォーマンス改善

```sql
/*
データベース内のテーブルから削除された行や更新された行によって生じたスペースを回収し、データベースのスペースを最適化する
PostgreSQLはデータを消しても実際には消えてはなく、削除フラグがついていて見えなくなっているだけの状態になっている。この削除データは定期的にきれいにする必要があり、この処理をVACUUMという
*/
VACUUM;

-- ANALYZEはテーブル内のデータの分布や統計情報を収集し、クエリプランナーが適切なインデックスや結合方法を選択するための情報を提供する
ANALYZE;

-- VACUUMとANALYZEは下記のように同時実行可能
vacuum analyze;

-- VACUUMとANALYZEの実行状況を確認
SELECT
  schemaname,
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM
  pg_stat_user_tables;
```

### 論理レプリケーション

論理レプリケーションスロットとはデータベース間でデータの受け渡しを行うための仕組み。
送信側のデータベース（プライマリ）は、特別なスロットを作成し、データをそのスロットに格納する。
受信側のデータベース（レプリカ）は、定期的にそのスロットからデータを取得して自身のデータベースに反映させる。
データの複製元をパブリッシャー、複製先をサブスクライバーと呼ぶ（PUB/SUBモデルをベースにしている）

```sql
-- 既存の論理レプリケーションスロットを確認
select * from pg_replication_slots;

-- 論理レプリケーションスロットを削除
SELECT pg_drop_replication_slot(スロット名);
```

### プライマリキー関連

- プライマリキーがないテーブル一覧を表示

```sql
-- その１
SELECT schemaname || '.' || tablename AS table_name FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
AND   tablename NOT IN (
    SELECT c.relname
    FROM 
        pg_constraint AS con
        JOIN pg_class AS c ON con.conrelid = c.oid
    WHERE con.contype = 'p'
);
-- その2
SELECT schemaname || '.' || tablename AS table_name FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
AND tablename NOT IN (
    SELECT tablename FROM pg_indexes WHERE indexname LIKE '%_pkey'
);
-- その3
SELECT table_schema || '.' || table_name AS table_name FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
AND   table_name NOT IN (
    SELECT table_name FROM information_schema.table_constraints WHERE constraint_type = 'PRIMARY KEY'
);
```

## [pgbench](https://www.postgresql.org/docs/current/pgbench.html)を使って測定

インストール

```sh
# amazonlinux2
sudo amazon-linux-extras install postgresql11
sudo yum install postgresql-contrib
```

初期化

```sh
# 基本
pgbench -i -h ホスト名 -p ポート番号 -U ユーザー名 -d データベース名
# スケーリングファクター数を調整
## スケーリングファクター数は1あたり、１０万件のデータ量(テーブル名:pgbench_accounts)があるので、数値が高いほど扱うデータ量が増え、負荷を高めたテストが可能
pgbench -i -h ホスト名 -p ポート番号 -U ユーザー名 -d データベース名 -s 2(スケーリングファクター数。デフォルトは1)
```

確認

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

- 後片付け

```psql
DROP TABLE IF EXISTS pgbench_accounts, pgbench_branches, pgbench_tellers, pgbench_history;
```

結果の見方

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

[mysqlとpsql](https://qiita.com/aosho235/items/c657e2fcd15fa0647471)

## サンプル環境作成

- Dockerfile

```Dockerfile
FROM postgres:17

ENV POSTGRES_USER=testuser
ENV POSTGRES_PASSWORD=testpass
ENV POSTGRES_DB=testdb

COPY init.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
```

- init.sql

```init.sql
-- Usersテーブルの作成
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Employeesテーブルの作成
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    position VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Productsテーブルの作成
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(20) NOT NULL UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usersテーブルに50,000件のデータを挿入
INSERT INTO users (username, email, first_name, last_name, age)
SELECT
    'user' || i::text,
    'user' || i::text || '@example.com',
    'FirstName' || i::text,
    'LastName' || i::text,
    20 + (i % 50)
FROM generate_series(1, 50000) AS i;

-- Employeesテーブルに50,000件のデータを挿入
INSERT INTO employees (employee_code, first_name, last_name, department, position, salary, hire_date)
SELECT
    'EMP' || LPAD(i::TEXT, 8, '0'),
    'FirstName' || i::TEXT,
    'LastName' || i::TEXT,
    CASE (i % 5)
        WHEN 0 THEN 'Sales'
        WHEN 1 THEN 'Engineering'
        WHEN 2 THEN 'Marketing'
        WHEN 3 THEN 'HR'
        ELSE 'Finance'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'Manager'
        WHEN 1 THEN 'Senior'
        WHEN 2 THEN 'Junior'
        ELSE 'Intern'
    END,
    30000 + (i % 100) * 1000,
    CURRENT_DATE - (i % 3650)
FROM generate_series(1, 50000) AS i;

-- Productsテーブルに50,000件のデータを挿入
INSERT INTO products (product_code, product_name, category, price, stock_quantity, description)
SELECT
    'PRD' || LPAD(i::TEXT, 8, '0'),
    'Product ' || i::TEXT,
    CASE (i % 6)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Books'
        WHEN 3 THEN 'Food'
        WHEN 4 THEN 'Furniture'
        ELSE 'Sports'
    END,
    (10 + (i % 990)) * 1.0,
    i % 1000,
    'Description for product ' || i::TEXT
FROM generate_series(1, 50000) AS i;

-- インデックスの作成
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_price ON products(price);
```

- Dockerfileとinit.sqlを用意して下記コマンドでテスト

```sh
# データベースコンテナの構築と起動
docker build -t postgres-test .
docker run -d -p 5432:5432 --name postgres-test postgres-test

# データベースの初期化完了を待つ（約30秒）
sleep 30

# データ確認
docker exec -it postgres-test psql -U testuser -d testdb -c "SELECT COUNT(*) FROM users;"
docker exec -it postgres-test psql -U testuser -d testdb -c "SELECT COUNT(*) FROM employees;"
docker exec -it postgres-test psql -U testuser -d testdb -c "SELECT COUNT(*) FROM products;"

# ダンプファイル作成（互換性の高いオプション）
docker exec -it postgres-test pg_dump -U testuser -d testdb --no-privileges --no-owner --no-comments > ファンプファイル名.sql
```
