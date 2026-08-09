#!/usr/bin/env bash
# ==============================================================================
# Script: owasp-scan.sh
# Description: Run OWASP ZAP security scan against a target URL
# Usage: ./owasp-scan.sh [TARGET_URL] [SCAN_TYPE] [REPORT_FORMAT]
#   SCAN_TYPE: baseline | full | api
#   REPORT_FORMAT: html | json | xml
# ==============================================================================

set -euo pipefail

TARGET_URL="${1:-http://localhost:8080}"
SCAN_TYPE="${2:-baseline}"
REPORT_FORMAT="${3:-html}"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:stable"
REPORT_DIR="$(pwd)/zap-reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${REPORT_DIR}/zap-${SCAN_TYPE}-${TIMESTAMP}.${REPORT_FORMAT}"

mkdir -p "$REPORT_DIR"

if ! command -v docker &>/dev/null; then
  echo "[ERROR] Docker is required to run OWASP ZAP."
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  OWASP ZAP Security Scan"
echo "  Target      : ${TARGET_URL}"
echo "  Scan Type   : ${SCAN_TYPE}"
echo "  Report      : ${REPORT_FILE}"
echo "═══════════════════════════════════════════════════════"
echo ""

# ─── Baseline Scan (passive, ~1-2 min) ───────────────────────────────────────
run_baseline() {
  echo "[INFO] Running ZAP Baseline (Passive) Scan..."
  docker run --rm \
    -v "${REPORT_DIR}:/zap/wrk/:rw" \
    "$ZAP_IMAGE" \
    zap-baseline.py \
    -t "$TARGET_URL" \
    -r "zap-baseline-${TIMESTAMP}.html" \
    -J "zap-baseline-${TIMESTAMP}.json" \
    -I || true  # -I: don't fail on warnings
  echo "[SUCCESS] Baseline scan complete."
}

# ─── Full Scan (active attack simulation, ~10-30 min) ─────────────────────────
run_full() {
  echo "[WARN] Running ZAP Full (Active) Scan — this may take 10-30 minutes..."
  echo "[WARN] Do NOT run against production without authorization!"
  read -rp "Proceed? Type 'yes' to confirm: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then echo "[ABORTED]"; exit 0; fi

  docker run --rm \
    -v "${REPORT_DIR}:/zap/wrk/:rw" \
    "$ZAP_IMAGE" \
    zap-full-scan.py \
    -t "$TARGET_URL" \
    -r "zap-full-${TIMESTAMP}.html" \
    -J "zap-full-${TIMESTAMP}.json" \
    -I || true
  echo "[SUCCESS] Full scan complete."
}

# ─── API Scan (OpenAPI / Swagger) ─────────────────────────────────────────────
run_api() {
  API_DEF="${4:-${TARGET_URL}/openapi.json}"
  echo "[INFO] Running ZAP API Scan against: ${API_DEF}"
  docker run --rm \
    -v "${REPORT_DIR}:/zap/wrk/:rw" \
    "$ZAP_IMAGE" \
    zap-api-scan.py \
    -t "$API_DEF" \
    -f openapi \
    -r "zap-api-${TIMESTAMP}.html" \
    -J "zap-api-${TIMESTAMP}.json" \
    -I || true
  echo "[SUCCESS] API scan complete."
}

case "$SCAN_TYPE" in
  baseline) run_baseline ;;
  full)     run_full "$@" ;;
  api)      run_api "$@" ;;
  *)
    echo "Usage: $0 <TARGET_URL> {baseline|full|api} [html|json|xml]"
    exit 1
    ;;
esac

echo ""
echo "[INFO] Reports saved in: ${REPORT_DIR}/"
ls -la "$REPORT_DIR/" | grep "zap-" || true
