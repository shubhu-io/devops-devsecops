#!/usr/bin/env bash
# ==============================================================================
# Script: run-trivy.sh
# Description: Execute Trivy vulnerability scanner for container images
# ==============================================================================

set -euo pipefail

IMAGE=${1:-"nginx:alpine"}

echo "[INFO] Running Trivy vulnerability scan on image: ${IMAGE}..."
if command -v trivy &>/dev/null; then
    trivy image --severity HIGH,CRITICAL "$IMAGE"
else
    echo "[WARN] Trivy scanner not installed. Install via setup.sh."
fi
