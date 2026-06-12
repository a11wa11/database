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
      - [postgres\_fdw](#postgres_fdw)
    - [メンテナンス・パフォーマンス改善](#メンテナンスパフォーマンス改善)
    - [プライマリキー関連](#プライマリキー関連)
  - [バックアップ](#バックアップ)
    - [dump](#dump)
    - [リストア](#リストア)
    - [論理レプリケーション](#論理レプリケーション)

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

### ユーザー操作

```sql
-- ユーザー作成
CREATE ROLE ユーザー名 with createdb login password 'パスワード';
-- ユーザーを確認
select * from pg_user;

-- ユーザーパスワード変更 ALTER ROLE と ALTER USER はほぼ同義。どちらを使ってもいい
ALTER ROLE ユーザー名 WITH PASSWORD 'パスワード';
ALTER USER ユーザー名 WITH PASSWORD 'パスワード';
```



### 拡張機能

```sql
-- インストール可能な拡張機能を確認する
SELECT * FROM pg_available_extensions;

-- 現在のデータベースにインストールされているすべての拡張機能の情報を取得
SELECT * FROM pg_extension;

-- 拡張機能インストール
create extension if not exists postgres_fdw(拡張機能名);

-- 指定拡張機能アップグレードコマンド  
ALTER EXTENSION 拡張機能名 UPDATE TO '新バージョン';

-- インストール済拡張機能でデフォルトバージョンより低いものを抽出
SELECT * FROM pg_available_extensions WHERE default_version > installed_version;
```

#### postgres_fdw

- fdw=Foreign Data Wrapperの略

PostgreSQLから外部のデータソース(別のPostgreSQLや、MySQL、CSVファイルなど)をあたかもローカルのテーブルのようにSELECTで参照できる仕組み

```sql
-- postgres_fdw拡張機能インストール
create extension if not exists postgres_fdw;

-- インストール済拡張機能一覧
SELECT * FROM pg_extension;

-- 外部データベースへの接続設定
create server 外部データベースの任意の名前
  foreign data wrapper postgres_fdw
  options (
    dbname 'データベース名',
    host 'ホスト名',
    port '5432'
  );

-- 外部データベース一覧
\des -- es = describe external servers

-- 外部データベースへのユーザーマッピング
create user mapping for current_user server 外部データベースの任意の名前 options (user 'ユーザー名', password 'パスワード');

\deu -- describe external user mappings

-- スキーマ作成
create schema スキーマ名;

-- スキーマ一覧
\dn

-- リモートテーブルを格納するためのローカル側のスキーマを作成
import foreign schema public from server 外部データベースの任意の名前 into スキーマ名;

-- リモートテーブル一覧
\det -- et = describe external tables
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

## バックアップ

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
