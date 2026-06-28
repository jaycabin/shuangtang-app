#!/bin/sh
set -e

# Railway 的 PostgreSQL 插件提供 DATABASE_URL
# 如果存在则自动解析为 DB_* 系列环境变量
if [ -n "$DATABASE_URL" ]; then
  echo "Parsing DATABASE_URL..."
  DB_USER=$(echo "$DATABASE_URL" | sed 's|postgres://\([^:]*\):.*|\1|')
  DB_PASS=$(echo "$DATABASE_URL" | sed 's|postgres://[^:]*:\([^@]*\)@.*|\1|')
  DB_HOST=$(echo "$DATABASE_URL" | sed 's|postgres://[^@]*@\([^:]*\):.*|\1|')
  DB_PORT=$(echo "$DATABASE_URL" | sed 's|postgres://[^@]*@[^:]*:\([^/]*\)/.*|\1|')
  DB_NAME=$(echo "$DATABASE_URL" | sed 's|postgres://[^@]*@[^/]*/\(.*\)|\1|')

  export DB_HOST DB_PORT DB_USER DB_PASSWORD DB_NAME
fi

echo "Running database migrations..."
./migrate up 2>/dev/null || echo "Migration skipped (DB may not be ready)"

echo "Starting server on port ${SERVER_PORT:-10080}..."
exec ./server
