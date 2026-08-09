#!/usr/bin/env bash
# ==============================================================================
# Script: vault-setup.sh
# Description: Install and initialize HashiCorp Vault in dev or server mode
# Usage: ./vault-setup.sh [MODE]
#   MODE: dev | server | status | unseal
# ==============================================================================

set -euo pipefail

MODE="${1:-dev}"
VAULT_VERSION="1.15.6"
VAULT_DATA_DIR="/opt/vault/data"
VAULT_CONFIG_DIR="/etc/vault.d"
VAULT_PORT=8200

# ─── Install Vault ────────────────────────────────────────────────────────────
install_vault() {
  if command -v vault &>/dev/null; then
    echo "[INFO] Vault already installed: $(vault --version)"
    return
  fi

  echo "[INFO] Installing HashiCorp Vault v${VAULT_VERSION}..."

  if command -v apt-get &>/dev/null; then
    # Ubuntu/Debian
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | \
      sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
      https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
      sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update -q && sudo apt-get install -y vault

  elif command -v dnf &>/dev/null; then
    # RHEL/CentOS/Fedora
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo dnf install -y vault
  else
    # Binary download fallback
    ARCH=$(uname -m)
    [ "$ARCH" = "x86_64" ] && ARCH="amd64"
    URL="https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip"
    curl -fsSL "$URL" -o /tmp/vault.zip
    unzip -o /tmp/vault.zip -d /usr/local/bin/
    chmod +x /usr/local/bin/vault
    rm /tmp/vault.zip
  fi

  vault --version && echo "[SUCCESS] Vault installed."
}

# ─── Dev Mode (in-memory, no TLS, auto-unsealed) ──────────────────────────────
start_dev() {
  echo "[INFO] Starting Vault in DEV mode (NOT for production)..."
  echo "[WARN] Data is stored IN MEMORY — lost on restart!"
  export VAULT_ADDR="http://127.0.0.1:${VAULT_PORT}"

  vault server -dev \
    -dev-root-token-id="devroot" \
    -dev-listen-address="127.0.0.1:${VAULT_PORT}" &

  sleep 2
  echo ""
  echo "══════════════════════════════════════════════════════"
  echo "  Vault DEV Server Running"
  echo "  URL        : http://127.0.0.1:${VAULT_PORT}"
  echo "  Root Token : devroot"
  echo "  UI         : http://127.0.0.1:${VAULT_PORT}/ui"
  echo "══════════════════════════════════════════════════════"
  echo ""
  echo "  Quick examples:"
  echo "    export VAULT_ADDR='http://127.0.0.1:8200'"
  echo "    export VAULT_TOKEN='devroot'"
  echo "    vault kv put secret/myapp db_password=s3cret"
  echo "    vault kv get secret/myapp"
}

# ─── Production Server Mode ───────────────────────────────────────────────────
start_server() {
  echo "[INFO] Configuring Vault for server (production) mode..."
  sudo mkdir -p "$VAULT_DATA_DIR" "$VAULT_CONFIG_DIR"
  sudo chown -R vault:vault "$VAULT_DATA_DIR" 2>/dev/null || true

  sudo tee "${VAULT_CONFIG_DIR}/vault.hcl" > /dev/null << EOF
storage "file" {
  path = "${VAULT_DATA_DIR}"
}

listener "tcp" {
  address     = "0.0.0.0:${VAULT_PORT}"
  tls_disable = 1  # Enable TLS in production!
}

api_addr     = "http://127.0.0.1:${VAULT_PORT}"
cluster_addr = "http://127.0.0.1:8201"
ui           = true
EOF

  echo "[INFO] Starting Vault service..."
  sudo systemctl enable vault && sudo systemctl start vault 2>/dev/null || \
    vault server -config="${VAULT_CONFIG_DIR}/vault.hcl" &

  sleep 2
  export VAULT_ADDR="http://127.0.0.1:${VAULT_PORT}"

  echo "[INFO] Initializing Vault..."
  vault operator init -key-shares=5 -key-threshold=3 | tee vault-init-output.txt
  echo ""
  echo "[IMPORTANT] Save vault-init-output.txt securely. It contains unseal keys!"
}

vault_status() {
  export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:${VAULT_PORT}}"
  echo "[INFO] Vault Status at ${VAULT_ADDR}..."
  vault status 2>/dev/null || echo "[WARN] Vault may be sealed or not running."
}

unseal_vault() {
  export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:${VAULT_PORT}}"
  echo "[INFO] Unsealing Vault (need 3 of 5 keys)..."
  for i in 1 2 3; do
    read -rsp "Enter Unseal Key ${i}/3: " UNSEAL_KEY
    echo ""
    vault operator unseal "$UNSEAL_KEY"
  done
  echo "[SUCCESS] Vault unsealed."
}

install_vault

case "$MODE" in
  dev)    start_dev ;;
  server) start_server ;;
  status) vault_status ;;
  unseal) unseal_vault ;;
  *)
    echo "Usage: $0 {dev|server|status|unseal}"
    exit 1
    ;;
esac
