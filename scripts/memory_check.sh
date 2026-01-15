#!/bin/bash

# === CONFIG ===
HOSTNAME=$(hostname)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Пороги (MB)
SWAP_WARN=300
SWAP_CRIT=1000

RAM_WARN=600
RAM_CRIT=300

# === COLLECT METRICS ===
SWAP_USED=$(free -m | awk '/Swap:/ {print $3}')
RAM_AVAILABLE=$(free -m | awk '/Mem:/ {print $7}')

STATUS="OK"
MESSAGE=""

# === CHECK SWAP ===
if [ "$SWAP_USED" -ge "$SWAP_CRIT" ]; then
  STATUS="CRITICAL"
  MESSAGE+="Swap critical: ${SWAP_USED}MB\n"
elif [ "$SWAP_USED" -ge "$SWAP_WARN" ]; then
  STATUS="WARNING"
  MESSAGE+="Swap warning: ${SWAP_USED}MB\n"
fi

# === CHECK RAM ===
if [ "$RAM_AVAILABLE" -le "$RAM_CRIT" ]; then
  STATUS="CRITICAL"
  MESSAGE+="Available RAM critical: ${RAM_AVAILABLE}MB\n"
elif [ "$RAM_AVAILABLE" -le "$RAM_WARN" ]; then
  [ "$STATUS" != "CRITICAL" ] && STATUS="WARNING"
  MESSAGE+="Available RAM warning: ${RAM_AVAILABLE}MB\n"
fi

# === OUTPUT ===
if [ "$STATUS" != "OK" ]; then
  echo "[$TIMESTAMP] [$STATUS] [$HOSTNAME]"
  echo -e "$MESSAGE"
fi
