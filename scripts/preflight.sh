#!/usr/bin/env bash
set -e

echo "[+] Project files:"
ls -l ~/minecraft-server | sed -n '1,10p'

echo "[+] Compose config check:"

if command -v docker-compose >/dev/null 2>&1; then
  docker-compose config >/dev/null && echo "    Compose OK (v1)"
elif docker compose version >/dev/null 2>&1; then
  docker compose config >/dev/null && echo "    Compose OK (v2)"
else
  echo "    ERROR: docker-compose not found"
fi
