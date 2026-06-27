#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Applying PostgreSQL migration..."
podman exec -i nexus-postgres psql -U nexus -d nexus < db/002_postgres_catalog.sql

echo "Rebuilding API..."
podman compose -f podman-compose.yml up -d --build nexus-api

echo "Syncing seed data into Postgres..."
sleep 3
curl -s -X POST http://127.0.0.1:8848/api/admin/seed | python3 -m json.tool

echo
echo "Health:"
curl -s http://127.0.0.1:8848/api/health | python3 -m json.tool
