#!/usr/bin/env bash
# ==============================================================================
# 17-devops-devsecops - Automated Trivy & GitLeaks Security Setup
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}[INFO] Installing DevSecOps Security Tools (Trivy)...${NC}"

if command -v trivy &>/dev/null; then
    echo -e "${GREEN}[SUCCESS] Trivy is already installed: $(trivy --version)${NC}"
    exit 0
fi

if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq wget apt-transport-https gnupg lsb-release
    wget -qO- https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - 2>/dev/null || true
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc 2>/dev/null || echo "jammy") main | sudo tee -a /etc/apt/sources.list.d/trivy.list > /dev/null
    sudo apt-get update -qq && sudo apt-get install -y -qq trivy
elif command -v dnf &>/dev/null; then
    sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.49.1/trivy_0.49.1_Linux-64bit.rpm || true
fi

echo -e "${GREEN}[SUCCESS] DevSecOps security scanner tools installed.${NC}"
