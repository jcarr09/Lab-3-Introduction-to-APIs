#!/usr/bin/env bash

mkdir -p ../logs ../data
set -euo pipefail
IFS=$'\n\t'
log_out="../logs/lab3.log"

log () {
    echo "$1" >> $log_out
}

cleanup () {
    log "[LAB3_END]"
}
trap cleanup EXIT

log "[LAB3_START]"

if ! command -v curl &> /dev/null; then
    log "[CURL_ERROR] curl is not installed. Please install curl to run this script."
    exit 1
else if ! command -v jq &> /dev/null; then
    log "[JQ_ERROR] jq is not installed. Please install jq to run this script."
    exit 1
fi
log "[BASH_OK]"

JOKE_URL="https://icanhazdadjoke.com/"
JOKE_IN="../data/dad_joke.json"
JOKE_OUT="../data/dad_joke.txt"
status=$(curl -sS -H 'Accept: application/json' -w '%{http_code}' -o "$JOKE_IN" "$JOKE_URL")
if [[ "$status" -ne 200 ]]; then
    log "[CURL_JOKE_ERROR] Failed to fetch joke. HTTP status code: $status"
    exit 1
fi
log "[CURL_JOKE_OK]"

jq -r '.id, .joke' "$JOKE_IN" > "$JOKE_OUT"
log "[JQ_JOKE_OK]"


DECK_API_URL="https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1"
DECK_CREATE_DATA="../data/deck_create.json"
DECK_DRAW_DATA="../data/deck_draw.json"
DECK_SUMMARY="../data/deck_summary.txt"
status=$(curl -sS -H 'Accept: application/json' -w '%{http_code}' -o "$DECK_CREATE_DATA" "$DECK_API_URL")
if [ "$status" -ne 200 ]; then
  log "[DECK_CREATE_ERROR] Failed to create deck. HTTP status code: $status"
  exit 1
fi
log "[DECK_CREATE_OK]"

deck_id=$(jq -r '.deck_id' "$DECK_CREATE_DATA")
DECK_API_URL="https://deckofcardsapi.com/api/deck/$deck_id/draw/?count=2"
status=$(curl -sS -H 'Accept: application/json' -w '%{http_code}' -o "$DECK_DRAW_DATA" "$DECK_API_URL")
if [ "$status" -ne 200 ]; then
  log "[DECK_DRAW_ERROR] Failed to draw cards. HTTP status code: $status"
  exit 1
fi
log "[DECK_DRAW_OK]"

jq -r '.cards[] | "\(.value) of \(.suit)"' "$DECK_DRAW_DATA" > "$DECK_SUMMARY"
echo "Remaining: $(jq -r '.remaining' "$DECK_DRAW_DATA")" >> "$DECK_SUMMARY"
log "[JQ_DECK_OK]"