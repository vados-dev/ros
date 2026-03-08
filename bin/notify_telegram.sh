#!/usr/bin/env bash


msg="${1:-no message}"

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "[notify][dry-run] $msg"
  exit 0
if [[ -z "${BOT_TOKEN:-}" || -z "${CHAT_ID:-}" ]]; then
  echo "[notify] BOT_TOKEN/CHAT_ID not set, skip"
  exit 0
fi

curl -fsS --connect-timeout 5 --max-time 10 \
-X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
-d "chat_id=${CHAT_ID}" \
--data-urlencode "text=${msg}" >/dev/null
# || true
