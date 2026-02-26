# SQL Server

## 使い方

## SSMS

SQL Server Management Studio

- 対象テーブルのDDL言語作成
  1. 対象DBに接続
  2. Tablesを展開して対象テーブルを右クリック
  3. Script Table as → CREATE To → New Query Editor Window
    または File / Clipboard に出力する 

- テーブルを絞り込み
  1. 対象DBに接続
  2. Tablesを展開して対象テーブルを右クリック
  3. フィルタを利用して絞り込む

## コマンド

### 接続

```sh
# 基本
sqlcmd -S ホスト名 -U ユーザー名 -P パスワード -d データベース名 -C

# 整形
sqlcmd -S ホスト名 -U ユーザー名 -P パスワード -d データベース名 -C -s "|" -W

# データベース切替
USE データベース名;
go
```

### 確認系

```sql
-- データベース
-- 一覧
SELECT name FROM sys.databases ORDER BY name;
go
-- 現在のデータベース
SELECT DB_NAME();
go

-- テーブル
SELECT name FROM sys.tables;
GO

-- テーブルのカラム名
-- \d+ テーブル名;

-- スキーマ
-- \dn

-- スキーマに所属するテーブル一覧
-- \d スキーマ名.*

-- ユーザー権限
-- \du

-- インデックス一覧
-- \di

-- データベース切替
-- \c データベース名
-- \connect データベース名

-- ユーザー一覧
-- select * from pg_user;

-- タイムゾーン
show timezone;

-- 現在時間
-- select now();

-- バージョン
SELECT @@VERSION;

--ディスク容量
-- SELECT pg_size_pretty(pg_database_size('データベース名'));

--インデックス一覧
-- SELECT * FROM pg_indexes;
```

