#!/bin/sh

set -ex
cd `dirname $0`

ISUCON_DB_HOST=${ISUCON_DB_HOST:-127.0.0.1}
ISUCON_DB_PORT=${ISUCON_DB_PORT:-3306}
ISUCON_DB_USER=${ISUCON_DB_USER:-isucon}
ISUCON_DB_PASSWORD=${ISUCON_DB_PASSWORD:-isucon}
ISUCON_DB_NAME=${ISUCON_DB_NAME:-isuports}
TENANT_DB_HOST=${TENANT_DB_HOST:-127.0.0.1}
TENANT_DB_PORT=${TENANT_DB_PORT:-3306}
TENANT_DB_USER=${TENANT_DB_USER:-isucon}
TENANT_DB_PASSWORD=${TENANT_DB_PASSWORD:-isucon}
TENANT_DB_NAME=${TENANT_DB_NAME:-isuports}

# MySQLを初期化
mysql -u"$ISUCON_DB_USER" \
		-p"$ISUCON_DB_PASSWORD" \
		--host "$ISUCON_DB_HOST" \
		--port "$ISUCON_DB_PORT" \
		"$ISUCON_DB_NAME" < init.sql

# SQLiteのデータベースを初期化
rm -f ../tenant_db/*.db
cp -r ../../initial_data/*.db ../tenant_db/
mysql -u"$TENANT_DB_USER" \
  -p"$TENANT_DB_PASSWORD" \
  --host "$TENANT_DB_HOST" \
  --port "$TENANT_DB_PORT" \
  $"TENANT_DB_NAME" < ./tenant/10_schema.sql
for db in $( ls ../../initial_data/*.db ); do
  mysql -u"$TENANT_DB_USER" \
    -p"$TENANT_DB_PASSWORD" \
    --host "$TENANT_DB_HOST" \
    --port "$TENANT_DB_PORT" \
    $"TENANT_DB_NAME" < <( ./sqlite3-to-sql $db )
done
