#!/usr/bin/env bash
# ==============================================================================
# Script: run-gitleaks.sh
# Description: Execute GitLeaks secret scanning audit on local Git history
# ==============================================================================

set -euo pipefail

echo "[INFO] Running GitLeaks hardcoded secret detection..."
if command -v gitleaks &>/dev/null; then
    gitleaks detect --verbose --redact
else
    echo "[WARN] GitLeaks not installed. Download binary from https://github.com/gitleaks/gitleaks"
fi
