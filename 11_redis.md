# redis

## コマンド

```redis
# redisサーバー起動
redis-server

# redisコマンド起動
redis-cli

# 接続
redis-cli -c -h ホスト名 -p ポート名(6379)

# keyの一覧確認
keys *

# keyの取得
get キー名

# keyの登録
set キー名 データ名

# サーバーの統計情報とメタデータを表示
INFO

# 現在のデータベースのキーの数を取得
DBSIZE

# 接続されているクライアントの情報を取得
CLIENT LIST

# サーバー上のすべてのリクエストをリアルタイムで監視
MONITOR
```
