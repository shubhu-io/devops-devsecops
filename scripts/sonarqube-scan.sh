#!/usr/bin/env bash
# ==============================================================================
# Script: sonarqube-scan.sh
# Description: Run SonarQube code quality scan via Docker or sonar-scanner CLI
# Usage: ./sonarqube-scan.sh [PROJECT_KEY] [SONAR_URL] [SONAR_TOKEN] [SRC_DIR]
# ==============================================================================

set -euo pipefail

PROJECT_KEY="${1:-devops-project}"
SONAR_URL="${2:-http://localhost:9000}"
SONAR_TOKEN="${3:-${SONAR_TOKEN:-}}"
SRC_DIR="${4:-.}"

if [ -z "$SONAR_TOKEN" ]; then
  echo "[ERROR] SONAR_TOKEN is required."
  echo "Usage: $0 <PROJECT_KEY> <SONAR_URL> <SONAR_TOKEN> [SRC_DIR]"
  echo "   or: export SONAR_TOKEN=<token> && $0 <PROJECT_KEY>"
  exit 1
fi

echo "[INFO] SonarQube Scan Configuration"
echo "  Project : ${PROJECT_KEY}"
echo "  Server  : ${SONAR_URL}"
echo "  Source  : ${SRC_DIR}"
echo ""

# ─── Option 1: sonar-scanner CLI ──────────────────────────────────────────────
if command -v sonar-scanner &>/dev/null; then
  echo "[INFO] Running sonar-scanner CLI..."
  sonar-scanner \
    -Dsonar.projectKey="$PROJECT_KEY" \
    -Dsonar.sources="$SRC_DIR" \
    -Dsonar.host.url="$SONAR_URL" \
    -Dsonar.login="$SONAR_TOKEN" \
    -Dsonar.scm.disabled=true

# ─── Option 2: Docker-based scan (fallback) ───────────────────────────────────
elif command -v docker &>/dev/null; then
  echo "[INFO] sonar-scanner CLI not found. Using Docker image..."
  docker run --rm \
    -e SONAR_HOST_URL="$SONAR_URL" \
    -e SONAR_LOGIN="$SONAR_TOKEN" \
    -v "$(realpath "$SRC_DIR"):/usr/src" \
    sonarsource/sonar-scanner-cli:latest \
    -Dsonar.projectKey="$PROJECT_KEY" \
    -Dsonar.sources=/usr/src \
    -Dsonar.scm.disabled=true
else
  echo "[ERROR] Neither sonar-scanner CLI nor Docker is available."
  echo "  Install: https://docs.sonarsource.com/sonarqube/latest/analyzing-source-code/scanners/sonarscanner/"
  exit 1
fi

echo ""
echo "[SUCCESS] SonarQube scan submitted!"
echo "  View results: ${SONAR_URL}/dashboard?id=${PROJECT_KEY}"

# ─── Optionally start a local SonarQube server ────────────────────────────────
start_sonarqube_local() {
  echo "[INFO] Starting local SonarQube server via Docker Compose..."
  cat > /tmp/sonarqube-compose.yml << 'EOF'
version: "3"
services:
  sonarqube:
    image: sonarqube:community
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonar
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
    depends_on:
      - db
  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonar
      - POSTGRES_DB=sonar
    volumes:
      - postgresql:/var/lib/postgresql
volumes:
  sonarqube_data:
  sonarqube_logs:
  postgresql:
EOF
  docker compose -f /tmp/sonarqube-compose.yml up -d
  echo "[INFO] SonarQube starting at http://localhost:9000 (admin/admin)"
}

# Uncomment to start local SonarQube:
# start_sonarqube_local
