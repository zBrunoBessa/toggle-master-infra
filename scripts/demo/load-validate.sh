#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="${NAMESPACE:-toggle-master}"
RATE_PER_SECOND="${RATE_PER_SECOND:-5}"
DURATION_SECONDS="${DURATION_SECONDS:-600}"
LOCAL_PORT="${LOCAL_PORT:-18080}"
BASE_URL="${BASE_URL:-}"
for value in "$RATE_PER_SECOND" "$DURATION_SECONDS" "$LOCAL_PORT"; do
  if [[ ! "$value" =~ ^[0-9]+$ ]] || (( ${#value} > 8 )) || (( 10#$value < 1 )); then
    echo "Taxa, duracao e porta devem ser inteiros positivos." >&2
    exit 2
  fi
done
RATE_PER_SECOND=$((10#$RATE_PER_SECOND))
DURATION_SECONDS=$((10#$DURATION_SECONDS))
LOCAL_PORT=$((10#$LOCAL_PORT))
if (( LOCAL_PORT > 65535 )); then echo "Porta invalida." >&2; exit 2; fi
if [[ -n "$BASE_URL" ]] && [[ ! "$BASE_URL" =~ ^https://[^/@?#]+(/[^?#]*)?$ ]] && [[ ! "$BASE_URL" =~ ^http://(127\.0\.0\.1|localhost|\[::1\])(:[0-9]+)?(/[^?#]*)?$ ]]; then
  echo "BASE_URL deve usar HTTPS ou HTTP em loopback." >&2
  exit 2
fi
pf_pid=""
pf_log=""
cleanup() {
  if [[ -n "$pf_pid" ]]; then kill "$pf_pid" 2>/dev/null || true; wait "$pf_pid" 2>/dev/null || true; fi
  if [[ -n "$pf_log" ]]; then rm -f -- "$pf_log"; fi
}
trap cleanup EXIT
trap "exit 130" INT
trap "exit 143" TERM
if [[ -z "$BASE_URL" ]]; then
  BASE_URL="http://127.0.0.1:$LOCAL_PORT"
  pf_log="$(mktemp)"
  kubectl -n ingress-nginx port-forward --address 127.0.0.1 svc/ingress-nginx-controller "$LOCAL_PORT:80" >"$pf_log" 2>&1 &
  pf_pid=$!
  ready=0
  for _ in $(seq 1 50); do
    if ! kill -0 "$pf_pid" 2>/dev/null; then cat "$pf_log" >&2; exit 1; fi
    if curl -sS --max-time 1 -o /dev/null "$BASE_URL/" 2>/dev/null; then ready=1; break; fi
    sleep 0.2
  done
  if [[ "$ready" != 1 ]] || ! kill -0 "$pf_pid" 2>/dev/null; then echo "Port-forward indisponivel." >&2; exit 1; fi
fi
BASE_URL="${BASE_URL%/}"
SERVICE_API_KEY="$(kubectl -n "$NAMESPACE" get secret toggle-master-secrets -o jsonpath='{.data.SERVICE_API_KEY}' | base64 -d)"
if [[ -z "$SERVICE_API_KEY" ]]; then echo "SERVICE_API_KEY ausente." >&2; exit 1; fi
echo "Gerando ~${RATE_PER_SECOND} req/s em $BASE_URL/validate por ${DURATION_SECONDS}s."
interval="$(awk -v r="$RATE_PER_SECOND" 'BEGIN { printf "%.6f", 1 / r }')"
end=$((SECONDS + DURATION_SECONDS))
declare -A counts=()
while (( SECONDS < end )); do
  for ((i=0; i<RATE_PER_SECOND && SECONDS<end; i++)); do
    code="$(printf 'Authorization: Bearer %s\n' "$SERVICE_API_KEY" | curl -s -o /dev/null -w '%{http_code}' --max-time 3 --header @- "$BASE_URL/validate" || true)"
    code="${code:-000}"
    counts[$code]=$(( ${counts[$code]:-0} + 1 ))
    sleep "$interval"
  done
  summary=""
  for status in "${!counts[@]}"; do summary+="$status=${counts[$status]} "; done
  printf '%s  %s\n' "$(date +%H:%M:%S)" "$summary"
  counts=()
done
