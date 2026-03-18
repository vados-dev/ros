#!/usr/bin/env bash

msg="${1:-no message}"

trim_wrapping_quotes() {
  local v="${1-}"
  if [[ "$v" =~ ^\"(.*)\"$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return
  fi
  if [[ "$v" =~ ^\'(.*)\'$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return
  fi
  printf '%s' "$v"
}

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "[notify][dry-run] $msg"
  exit 0
fi

BOT_TOKEN_CLEAN="$(trim_wrapping_quotes "${BOT_TOKEN:-}")"
CHAT_ID_CLEAN="$(trim_wrapping_quotes "${CHAT_ID:-}")"
TG_PARSE_MODE_CLEAN="$(trim_wrapping_quotes "${TGParseMode:-}")"
TG_DISABLE_PREVIEW_CLEAN="$(trim_wrapping_quotes "${TGDisableWebPagePreview:-}")"

if [[ -z "$BOT_TOKEN_CLEAN" || -z "$CHAT_ID_CLEAN" ]]; then
  echo "[notify] BOT_TOKEN/CHAT_ID not set, skip"
  exit 0
fi
curl_args=(
  -fsS
  --connect-timeout 5
  --max-time 10
  -X POST "https://api.telegram.org/bot${BOT_TOKEN_CLEAN}/sendMessage"
  -d "chat_id=${CHAT_ID_CLEAN}"
  --data-urlencode "text=${msg}"
)

if [[ -n "$TG_PARSE_MODE_CLEAN" ]]; then
  curl_args+=( -d "parse_mode=${TG_PARSE_MODE_CLEAN}" )
fi

if [[ -n "$TG_DISABLE_PREVIEW_CLEAN" ]]; then
  curl_args+=( -d "disable_web_page_preview=${TG_DISABLE_PREVIEW_CLEAN}" )
fi

curl "${curl_args[@]}" >/dev/null
