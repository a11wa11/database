# データベース

- [データベース](#データベース)
  - [用語](#用語)
    - [CRUD](#crud)
  - [構成](#構成)
  - [クエリ](#クエリ)
  - [SQL構文ルール](#sql構文ルール)

## 用語

- DDL
  - Data Definition Language(データ定義言語)
  - `CREATE TABLE`でテーブルを新規作成、`ALTER TABLE`で既存テーブルの列や制約を追加・変更、`DROP TABLE`でテーブルを削除するといった操作が該当
  - 他にも`CREATE INDEX`でインデックスを作成、`CREATE VIEW`でビューを作成するのもDDL
- DML
  - Data Manipulation Language
  - テーブル内のデータを操作するもの
  - INSERT でデータを挿入、UPDATE で既存データを更新、DELETE でデータを削除、SELECT でデータを取得するといった操作がDML
- トランザクション
  - データベースの処理単位。複数のSQL文をまとめて処理することで、データの整合性を保つ仕組み
- レプリケーション
  - データベースの複製を作成し、複数のデータベースサーバーに同じデータを持たせることで、データの冗長化や負荷分散を行う仕組み
- バイナリログレプリケーション
  - データベースの変更をログ形式で記録し、そのログを他のデータベースサーバーに転送して再実行することで、データベースの複製を行う仕組み
- パーティション(Partitioning)
  - テーブルを複数の小さなテーブル(パーティション)に分割することで、データの管理を容易にする機能
  - 水平パーティション(Horizontal Partitioning)
    - レコードを条件（例えば、日付やIDの範囲）に基づいて複数のサブテーブルに分割する
  - 垂直パーティション(Vertical Partitioning)
    - テーブルのカラムをグループ化し、関連性の高いカラムごとに別テーブルに分ける方法
- 名寄せ
  - 同一のデータを一つにまとめること
- 陳腐化したデータ
  - 古くなったデータのことで本来最新の状態であるべきデータが、何らかの理由（キャッシュ、レプリケーション遅延、同期ミスなど）で更新されず、古い値のまま表示・利用されている状態
  - 「更新済みのソースがあるのに、利用者が依然として以前の値を見る」状況を指す
- 目標復旧時点(RPO)
  - データ損失を許容できる最大の時間間隔
- 目標復旧時間(RTO)
  - システム障害から復旧するまでの最大許容時間

### CRUD

- Create
  - データの新規作成
  - insert文
- Read
  - データの読み込み
  - select文
- Update
  - データの更新(履歴残すか、完全上書きか要検討)
  - update文
- Delete
  - データの削除(非表示か完全削除か検討)
  - delete文

## 構成

以下のようにデータベースは3段構造になっていることが基本

- データベース
  - スキーマ: 複数のテーブルをグルーピングして管理するための仕組み
    - テーブル

- クライアントからのURI形式の接続文字列例
  - `DatabaseURL=postgresql://ユーザー名:パスワード@ホスト名:ポート番号/データベース名`

## クエリ

- select

```sql
-- ソート昇順
select * from テーブル名 order by カラム名 asc;
-- ソート降順
select * from テーブル名 order by カラム名 desc;
-- 時刻指定
select * from テーブル名 where created_at >= '20240101 050000'::TIMESTAMP limit 100;

-- テーブルのカラム名を横並びで取得する
select group_concat(カラム名 separator ', ') as columns from information_schema.columns where table_schema = 'DB名' and table_name = 'テーブル名' order by ordinal_position asc;

-- データをグループ化する
select カラム名1, カラム名2 from テーブル名 group by カラム名1;

-- データをグループ化し、条件抽出する
select カラム名1, カラム名2 from テーブル名 group by カラム名1 having カラム名>1;

-- 複数の対象のどれかに該当する値を取得
select * from テーブル名 where カラム名 in(1,2,3);

-- テーブルのカラム数を取得
select count(カラム名) from information_schema.columns where table_name='テーブル名' and table_schema='DB名';

-- 外部キー確認
select * from information_schema.key_column_usage where table_schema='DB名' and table_name='テーブル名';
```

- update

```sql
update TABLE_NAME set COLUMN_NAME1='AAA', COLUMN_NAME2='BBB',updated_at=now() where id=999;
```

- delete

```sql
delete from TABLE_NAME; -- テーブルを削除する
```

- 複数insert

```sql
insert into words (english, japanese,created_at,updated_at) values 
('availability','可用性',now(),now()),
('arn','Amazon リソースネーム (ARN)',now(),now());
```

- drop

```sql
-- 指定dデータベース削除
drop database データベース名;
-- 指定テーブル削除
drop table テーブル名;
-- 依存テーブルも含めて指定テーブルを削除
drop table テーブル名 cascade;
```

- alter

```sql
-- 型変更
ALTER TABLE テーブル名 ALTER COLUMN カラム名 TYPE タイプ;

-- カラム追加
ALTER TABLE テーブル名 ADD COLUMN カラム名 TYPE タイプ;
```

- トランザクション

```sql
begin;
update table_name set column_name1=1, column_name2='test' where id=999;
rollback; -- 戻す
commit;
```

## SQL構文ルール

- 優先度

下に行くほど優先度が下がる(上ほど処理の優先度が高い)

| 機能 | 構文 |
| -- | -- |
| テーブルの指定 | FROM |
| 結合 | ON / JOIN |
| 取得条件 | WHERE |
| グループ化 | GROUP BY |
| 関数 | COUNT / SUM / AVG / MIN |
| 取得条件 | HAVING |
| 検索 | SELECT / DISTINCT |
| 順序 | ORDER BY |
| LIMIT | LIMIT |

- `select ① from ②;`
  - ①の部分に入れたカラムを指定し、②のテーブルから取得してくる。基本selectとfromはセットで使い単体では使用しない
  - テキスト ""で囲む
  - 数値 クオテーション不要
  - 日付 ""(ダブルクオテーション)、もしくは’’(シングルクオテーション)で囲む
- `select ① from ② where ③ = ④;`
  - ③のカラムの中で④と一致するものを取得する
- `select distinct(①) from ②;`
  - ①で指定したカラムで重複したものを削除する
- SUM
  - `select SUM(①) from ②;`
    - ①のカラムの合計値を取得。whereと併用可能
- AVG
  - `select AVG(①) from ②;`
    - ①のカラムの平均値を取得。whereと併用可能
- MAX
  - `select MAX(①) from ②;`
    - ①のカラムの最大値を取得。whereと併用可能
- MIN
  - `select MIN(①) from ②;`
    - ①のカラムの最小値を取得。whereと併用可能。ただし、nullはカウントされない
- COUNT
  - `select COUNT(①) from ②;`
    - ①のカラムのデータ合計値を取得。whereと併用可能。ただし、nullはカウントされない
- GROUP BY
  - 指定したカラムで、完全に同一のデータを持つレコード同士がグループ化する。sumやavgと組み合わせて集計しやすくなる。コンマで区切り、複数のグループ化も可能
- 検索（where）、グループ化（group by）、関数（sum,count）、havingの順番で行われる
- HAVING
  - `group by ① having ②;`
    - ②の条件を満たすグループを取得することができる。WHEREはグループ化される前のテーブル全体を検索対象とするのに対し、HAVINGはGROUP BYによってグループ化されたデータを検索対象
- AS
  - `select ① as "②"「カラム名 AS "名前"`
    - カラム名に定義する名前を指定
- JOIN
  - `join ① on ②`
    - ①のテーブルを結合し、結合条件は、「ON テーブル名.カラム名 = テーブル名.カラム名」で指定。JOINを含んだSQL文では、はじめにJOINが実行されます
    - 複数のテーブルに同じカラム名が存在するときは、「テーブル名.カラム名」で指定
    - LEFT JOIN FROMで指定したテーブルのレコードを全て取得します。外部キーがNULLのレコードもNULLのまま実行結果に表示されます
- サブクエリ
  - SQL文の中に他のSQL文を入れることができる。サブクエリの中にセミコロンは不要
