#!/usr/bin/env bash
set -e

TS=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DIR="$HOME/backups"
SRC="$HOME/minecraft-server/data"
ARCHIVE="$BACKUP_DIR/minecraft_$TS.tar.gz"

tar -czf "$ARCHIVE" -C "$SRC" .

echo "Backup created: $ARCHIVE"
