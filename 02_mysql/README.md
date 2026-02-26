# mysql

- [mysql](#mysql)
  - [インストール](#インストール)
    - [CentOS7](#centos7)
  - [クエリ](#クエリ)
    - [確認](#確認)
    - [プロシージャ](#プロシージャ)
  - [設定関連](#設定関連)
    - [出力系](#出力系)
    - [linuxコマンドを実行](#linuxコマンドを実行)

## インストール

### CentOS7

1, MariaDBがインストールされている場合はこれからインストールするMySQLと競合を起こさないように削除

```sh
sudo yum remove mariadb-libs
sudo rm -rf /var/lib/mysql
```

2, MySQL公式のyumリポジトリの追加(yumでもrpmでも可)

```sh
# 5.7の追加
sudo rpm -ivh http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
# 8.0の追加
sudo yum install -y http://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
```

3, MySQLのインストール

```sh
sudo yum install mysql-community-server

# バージョンを確認
mysqld --version
mysqld  Ver 5.7.14 for Linux on x86_64 (MySQL Community Server (GPL))
```

3, MySQLのインストール-別のやり方

```sh
yum localinstall -y http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
yum install -y mysql-community-client-5.7.34-1.el7.x86_64
```

4, MySQLの起動と自動化設定

```sh
sudo systemctl start mysqld.service
sudo systemctl enable mysqld.service
```

5, MySQLの初期パスワード確認  
※`MySQL5.7`以降では、初回起動時に初期パスワードが生成されるので、ログファイルから生成されたパスワードを確認

```sh
$ sudo cat /var/log/mysqld.log | grep password
2016-09-01T13:09:03.337119Z 1 [Note] A temporary password is generated for root@localhost: xxxx!XXX;XXXX
```

6, MySQLのセキュリティ設定
mysql_secure_installationコマンドを実行して、MySQLのセキュリティ設定を行う

<details>
  <summary>コード</summary>
    <code>
$ mysql_secure_installation

Securing the MySQL server deployment.

Enter password for user root: # ログファイルから取得した初期パスワードを入力します

The existing password for the user account root has expired. Please set a new password.

New password: # root ユーザの新規パスワードを入力します

Re-enter new password: # 確認用にもう一度入力します
The 'validate_password' plugin is installed on the server.
The subsequent steps will run with the existing configuration
of the plugin.
Using existing password for root.

Estimated strength of the password: 100
Change the password for root ? ((Press y|Y for Yes, any other key for No) : y

By default, a MySQL installation has an anonymous user,
allowing anyone to log into MySQL without having to have
a user account created for them. This is intended only for
testing, and to make the installation go a bit smoother.
You should remove them before moving into a production
environment.

Remove anonymous users? (Press y|Y for Yes, any other key for No) : y # 匿名ユーザーアカウントを削除
Success.

Normally, root should only be allowed to connect from
'localhost'. This ensures that someone cannot guess at
the root password from the network.

Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y # ローカルホスト以外からアクセス可能な root アカウントを削除
Success.

By default, MySQL comes with a database named 'test' that
anyone can access. This is also intended only for testing,
and should be removed before moving into a production
environment.

Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y # test データベースの削除
 Dropping test database...
Success.

 Removing privileges on test database...
Success.

Reloading the privilege tables will ensure that all changes
made so far will take effect immediately.

Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
Success.

All done!
</code>
</details>

7, 設定変更

- MySQL5.7からパスワードの有効期限がデフォルトで360日になり、360日を経過するとパスワードの変更を促されてMySQLにログインできなくなる。  
default_password_lifetime の値を `0` に変更して、この有効期限の設定を無効にする
また、デフォルトの文字コードも UTF-8 に変更

```sh
/etc/my.cnf
[mysqld]
.
.
character-set-server = utf8
default_password_lifetime = 0
```

- [ポート番号を変更](https://oreno-it3.info/archives/440)

```sh
# /etc/mysql/mysql.conf.d/mysql.conf
port = 3307
```

8, MySQLを再起動させ、設定内容を反映

```sh
sudo systemctl restart mysqld.service
```

9, 接続

```sh
mysql -u ユーザー名 -D DB名 -p -P ポート番号
```

## クエリ

- 縦表示

```sql
select * from テーブル名\G;
```

- 日時・時刻系 : [参考](https://www.wakuwakubank.com/posts/335-mysql-sql-function-date/)

```sql
select now();
select utc_time();
select date();
```

### 確認

- ポート確認

```sql
mysql> status

mysql> show variables like 'port'
```

- 疎通確認

```sql
mysqladmin ping -h xxx.xxx.xxx.xxx -u hoge -p fuga
```

### プロシージャ

```sql
# 登録
DELIMITER //
drop procedure if exists `proc_test01` //
CREATE PROCEDURE proc_test01(IN input varchar(255))
BEGIN

　　SELECT USER_NAME FROM USER_DATA WHERE USER_ID = input;

END;
//
DELIMITER ;

# 一覧確認-1
SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE';

# 一覧確認-2
SHOW PROCEDURE STATUS;

# 詳細確認
SHOW CREATE PROCEDURE プロシージャ名;

# 実行
call プロシージャ名(引数)

# 削除
DROP PROCEDURE [プロシージャ名];
```

- プロシージャで動的にテーブル名を指定する

```sql
# 登録
DELIMITER //
drop procedure if exists `proc_test02` //
CREATE PROCEDURE proc_test01(IN input_table varchar(255))
BEGIN
    if (select count(*) from information_schema.columns where table_name=input_table and table_schema='db_name' and column_name='column_name1') > 0 then
      set @s = concat('select * from `, input_table, '` where column_name='999');
    elseif (select count(*) from information_schema.columns where table_name=input_table and table_schema='db_name' and column_name='column_name2') > 0 then
      set @s = concat('select * from `, input_table, '` where column_name='888');
    else 
      set @s = concat('select * from `, input_table);
    end if;
    prepare stmt from @s;
    execute stmt;

END;
//
DELIMITER ;
```

## 設定関連

- パスワードの変更

```sql
set password = 'new_password'
```

- 文字コード変更

```sql
# 初期設定では日本語入力受け付けない場合があるため、/etc/my.cnf に下記を追加し、mysqlを再起動

[mysqld]
character-set-server = utf8
```

- クエリ結果をlessで表示且つ横スクロール可能にする

```sql
mysql> pager less -iSN
# -i → 検索時に大小文字を区別しない
# -S → 行を折り返さない
# -N → 行番号を表示
```

- カラムのNULL成約を変更する(Nullを許可)

```sql
alter table TABLE_NAME modify COLUMN_NAME varchar(255);
```

### 出力系

- dump

```sql
# dump
mysqldump -u user_name -p -h host_name db_name table_name > OUTPUT_FILE_NAME
# 取り込み
mysql -u user_name -p -h host_name db_name table_name < OUTPUT_FILE_NAME
```

- csv出力

```sql
# csvに出力には下記の結果で表示される場所にのみ出力可能。空白であればcsv出力不可
SELECT @@global.secure_file_priv;
# select結果をcsv出力
SELECT * FROM table_name INTO OUTFILE '/tmp/table_name.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"';
```

### linuxコマンドを実行

- linuxコマンド実行には`\!` をつけて実行する

```sql
mysql> \! test.sql
mysql> source test.sql
```
