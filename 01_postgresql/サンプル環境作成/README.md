# サンプル環境作成

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
