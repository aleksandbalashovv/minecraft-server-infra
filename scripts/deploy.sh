#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
PROJECT_DIR="$HOME/minecraft-server"
DATA_DIR="$PROJECT_DIR/data"
BASELINE_FILE="$PROJECT_DIR/scripts/baseline.sha256"
CONTAINER_NAME="minecraft"

WATCH_PATHS=(
  "plugins"
  "config"
  "server.properties"
)

# ==================

echo "======================================="
echo " Minecraft deploy & integrity check"
echo " Time: $(date)"
echo "======================================="

cd "$DATA_DIR"

echo "[1] Collecting current file hashes..."

CURRENT_HASHES=$(mktemp)

for path in "${WATCH_PATHS[@]}"; do
  if [ -e "$path" ]; then
    find "$path" -type f -exec sha256sum {} \; >> "$CURRENT_HASHES"
  fi
done

if [ ! -f "$BASELINE_FILE" ]; then
  echo " No baseline found. Creating initial baseline."
  cp "$CURRENT_HASHES" "$BASELINE_FILE"
  rm "$CURRENT_HASHES"
  echo " Baseline created. No restart needed."
  exit 0
fi

echo "[2] Comparing with baseline..."

DIFF_OUTPUT=$(mktemp)

diff -u "$BASELINE_FILE" "$CURRENT_HASHES" > "$DIFF_OUTPUT" || true

if [ ! -s "$DIFF_OUTPUT" ]; then
  echo " No changes detected. Restart skipped."
  rm "$CURRENT_HASHES" "$DIFF_OUTPUT"
  exit 0
fi

echo " Changes detected:"
echo "-------------------------"
cat "$DIFF_OUTPUT"
echo "-------------------------"
echo "[PRE-CHECK] Validating configs..."

# ---- spark JSON check ----
SPARK_CONFIG="$DATA_DIR/plugins/spark/config.json"

if [ -f "$SPARK_CONFIG" ]; then
  if ! jq empty "$SPARK_CONFIG" >/dev/null 2>&1; then
    echo "ERROR: spark/config.json is not valid JSON"
    echo "Fix the file before deploying."
    exit 1
  fi
  echo " spark config.json OK"
else
  echo " spark config.json not found (will be generated)"
fi

echo "[3] Restarting Minecraft container..."
docker restart "$CONTAINER_NAME"

echo "[4] Waiting for container health..."

MAX_WAIT=120   # seconds
INTERVAL=5
ELAPSED=0

while true; do
  HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")

  echo "  -> health: $HEALTH ($ELAPSED s)"

  if [ "$HEALTH" = "healthy" ]; then
    echo " Server is healthy."
    break
  fi

  if [ "$HEALTH" = "unhealthy" ]; then
    echo " ERROR: container reported unhealthy!"
    break
  fi

  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo " WARNING: healthcheck timeout after ${MAX_WAIT}s"
    break
  fi

  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")

echo " Container health: $HEALTH"

if [ "$HEALTH" = "healthy" ]; then
  echo " Server reported healthy."
elif [ "$HEALTH" = "starting" ]; then
  echo " Server still starting. This is acceptable for Minecraft."
else
  echo " Server health state: $HEALTH"
fi

echo "[5] Updating baseline..."
cp "$CURRENT_HASHES" "$BASELINE_FILE"

rm "$CURRENT_HASHES" "$DIFF_OUTPUT"

echo " Deploy finished."
