# 🛡️ devops-devsecops — DevSecOps Pipeline Security Execution Repository

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/shubhu-io/devops-devsecops/actions/workflows/devsecops-ci.yml/badge.svg)](https://github.com/shubhu-io/devops-devsecops/actions/workflows/devsecops-ci.yml)
[![Learning Hub](https://img.shields.io/badge/DevOps-Learning%20Hub-blue.svg)](https://github.com/shubhu-io/devops-learning)

Production DevSecOps toolchain for embedding security into CI/CD pipelines. Covers secrets detection (Gitleaks), container scanning (Trivy), SAST (SonarQube), DAST (OWASP ZAP), IaC scanning (Checkov/tfsec), and secrets management (HashiCorp Vault).

---

## ⚡ Quick Start

```bash
git clone https://github.com/shubhu-io/devops-devsecops.git
cd devops-devsecops
chmod +x setup.sh
./setup.sh          # Installs Gitleaks, Trivy, Checkov, tfsec, OWASP ZAP

# Scan your repo for secrets immediately
./scripts/run-gitleaks.sh

# Scan a Docker image for vulnerabilities
./scripts/run-trivy.sh nginx:latest
```

---

## 📂 Repository Structure

```
devops-devsecops/
├── setup.sh                          # Install all DevSecOps tools
├── uninstall.sh                      # Remove security tools
├── .github/workflows/
│   └── devsecops-ci.yml             # CI: Gitleaks + Trivy + Checkov + ShellCheck (weekly)
└── scripts/
    ├── run-gitleaks.sh              # Secret scanner for git repos
    ├── run-trivy.sh                 # Container & filesystem vulnerability scanner
    ├── sonarqube-scan.sh            # SAST: SonarQube code quality scan
    ├── owasp-scan.sh                # DAST: OWASP ZAP baseline/full/API scan
    └── vault-setup.sh               # HashiCorp Vault installer & initializer
```

---

## 🛠️ Scripts Reference

| Script | Tool | Type | Usage |
|--------|------|------|-------|
| `run-gitleaks.sh` | Gitleaks | Secret Detection | `./scripts/run-gitleaks.sh /path/to/repo` |
| `run-trivy.sh` | Trivy | Container/FS Scan | `./scripts/run-trivy.sh nginx:latest` |
| `sonarqube-scan.sh` | SonarQube | SAST | `./scripts/sonarqube-scan.sh my-project http://localhost:9000 $TOKEN` |
| `owasp-scan.sh` | OWASP ZAP | DAST | `./scripts/owasp-scan.sh https://myapp.com baseline` |
| `vault-setup.sh` | HashiCorp Vault | Secrets Mgmt | `./scripts/vault-setup.sh dev` |

---

## 🔐 DevSecOps Shift-Left Checklist

```
✅ Pre-commit: Gitleaks secret scan (git hook)
✅ PR gate:    SonarQube SAST + Trivy image scan
✅ CD gate:    OWASP ZAP DAST (staging environment)
✅ Runtime:    Vault for secrets injection (no env vars with keys)
✅ Infra:      Checkov + tfsec for Terraform IaC misconfig
✅ Weekly:     Full Gitleaks history scan + Trivy DB update
```

---

## 📚 Learning Hub

For OWASP Top 10, SAST vs DAST, supply chain security, and Zero Trust theory, visit the [DevOps Learning Hub](https://github.com/shubhu-io/devops-learning).

---

## 📄 License

Licensed under [MIT](LICENSE).
