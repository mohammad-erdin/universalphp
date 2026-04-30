#!/bin/sh
set -e

# Start cron in the background before the main process
if command -v crond >/dev/null 2>&1; then
  echo "Starting cron..."
  crond
elif command -v cron >/dev/null 2>&1; then
  echo "Starting cron..."
  cron
fi
