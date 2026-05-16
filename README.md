# 🛡️ DevSecOps CI/CD Pipeline with Automated VAPT

<div align="center">

![DevSecOps](https://img.shields.io/badge/DevSecOps-Pipeline-blue?style=for-the-badge)
![OWASP](https://img.shields.io/badge/OWASP-Top%2010-red?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Tools](https://img.shields.io/badge/Tools-7%20Integrated-orange?style=for-the-badge)
![Cost](https://img.shields.io/badge/Licensing%20Cost-USD%200-brightgreen?style=for-the-badge)

**A fully automated, open-source DevSecOps CI/CD pipeline integrating 7 security tools,
covering all OWASP Top 10 categories, with unified vulnerability management.**

[📖 Documentation](#documentation) •
[🚀 Quick Start](#quick-start) •
[🔧 Tools](#security-tools) •
[📊 Results](#results) •
[🤝 Contributing](#contributing)

</div>

---

## 📌 Overview

This project implements a complete **DevSecOps CI/CD pipeline** from scratch using
entirely open-source tools on a single Ubuntu VM (or AWS EC2). Every time a developer
pushes code to GitHub, the pipeline automatically runs **11 security stages** covering
all **OWASP Top 10 2021** categories and consolidates all findings in **DefectDojo**.

### Key Numbers

| Metric | Value |
|---|---|
| Security Tools Integrated | 7 |
| Pipeline Stages | 11 |
| OWASP Top 10 Coverage | 10/10 (100%) |
| Total Findings (on DVWA) | 965 |
| Pipeline Execution Time | ~28 minutes |
| Licensing Cost | USD 0 |
| Test Cases Passed | 20/20 (100%) |

---

## 🏗️ Architecture

```
Developer → GitHub Push
               │
               ▼ (webhook — 30 seconds)
           Jenkins CI
               │
    ┌──────────┼──────────┐
    │    11 Security       │
    │    Stages Run        │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────┐
    │     DefectDojo       │  ← All findings consolidated
    │   965 Findings       │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────┐
    │  Grafana Dashboard   │  ← Real-time monitoring
    └─────────────────────┘
```

### Infrastructure (Single VM)

```
Ubuntu 22.04 LTS VM
├── Jenkins          (port 8080)  — CI/CD Orchestration
├── SonarQube CE     (port 9000)  — SAST
├── DefectDojo       (port 8090)  — Vulnerability Management
├── Grafana          (port 3000)  — Monitoring
└── DVWA             (port 8888)  — Target Application
```

---

## 🔧 Security Tools

| Tool | Version | Category | OWASP | Finding |
|---|---|---|---|---|
| SonarQube CE | 26.4.0 | SAST | A04+A01 | 8 security issues |
| Trivy | 0.70+ | Container | A06+A08 | 145 HIGH CVEs |
| OWASP ZAP | Stable | DAST | A01+A05+A07 | 21 findings |
| Nikto | 2.1.5 | Server | A05 | 11 findings |
| SQLMap | 1.6.4 | Injection | A03 | SQL injection confirmed |
| testssl.sh | 3.3dev | TLS/Crypto | A02 | No HTTPS detected |
| OWASP DC | 9.0.9 | SCA | A06 | Library CVEs |

---

## 🚀 Quick Start

### Option A — Automated Deploy (Recommended)

```bash
# 1. Clone this repo
git clone https://github.com/Amar9340/devsecops-pipeline.git
cd devsecops-pipeline

# 2. Edit configuration
nano .env

# 3. Deploy everything
sudo bash scripts/deploy.sh
```

**Done. Wait 15 minutes. Everything installs itself.**

### Option B — Manual Step by Step

See [docs/INSTALLATION.md](docs/INSTALLATION.md)

### Requirements

- Ubuntu 22.04 LTS
- RAM: 12 GB minimum (16 GB recommended)
- Storage: 60 GB minimum
- CPU: 4 cores minimum

---

## 📁 Repository Structure

```
devsecops-pipeline/
│
├── 📄 README.md                    ← You are here
├── 📄 Jenkinsfile                  ← Complete pipeline definition
├── 📄 .env                         ← Configuration (copy from .env.example)
├── 📄 .env.example                 ← Template — fill this in
├── 📄 .gitignore                   ← Sensitive files excluded
│
├── 📁 docs/                        ← Full documentation
│   ├── INSTALLATION.md             ← Step-by-step install guide
│   ├── CONFIGURATION.md            ← All config options explained
│   ├── TOOLS.md                    ← Each tool explained
│   ├── OWASP_COVERAGE.md           ← OWASP Top 10 mapping
│   ├── HARDENING.md                ← Security hardening guide
│   ├── TROUBLESHOOTING.md          ← Common issues and fixes
│   └── RESULTS.md                  ← Pipeline results and findings
│
├── 📁 infrastructure/              ← Infrastructure setup
│   ├── netplan.yaml                ← Static IP configuration
│   ├── ufw-rules.sh                ← Firewall rules
│   └── vm-setup.md                 ← VirtualBox VM setup guide
│
├── 📁 pipeline/                    ← Pipeline configuration
│   ├── Jenkinsfile                 ← Main pipeline (symlink)
│   └── stages/                     ← Individual stage scripts
│       ├── 01-clone.sh
│       ├── 02-sonarqube.sh
│       ├── 03-docker-build.sh
│       ├── 04-trivy.sh
│       ├── 05-dependency-check.sh
│       ├── 06-testssl.sh
│       ├── 07-sqlmap.sh
│       ├── 08-zap.sh
│       ├── 09-nikto.sh
│       ├── 10-headers.sh
│       └── 11-upload-dojo.sh
│
├── 📁 security/                    ← Security hardening configs
│   ├── sshd_config                 ← Hardened SSH config
│   ├── fail2ban-jail.local         ← Fail2Ban rules
│   ├── docker-daemon.json          ← Docker hardening
│   ├── audit-rules.conf            ← Audit logging rules
│   └── ufw-rules.sh                ← Firewall setup
│
├── 📁 monitoring/                  ← Grafana and monitoring
│   ├── grafana-datasource.yaml     ← DefectDojo data source config
│   └── dashboard.json              ← Grafana dashboard export
│
├── 📁 configs/                     ← Tool configurations
│   ├── sonarqube-project.properties← SonarQube project config
│   └── defectdojo-setup.md         ← DefectDojo initial setup
│
└── 📁 scripts/                     ← Automation scripts
    ├── deploy.sh                   ← One-command full deploy
    ├── start.sh                    ← Start all services
    ├── stop.sh                     ← Stop all services
    ├── status.sh                   ← Check all service status
    └── reset-passwords.sh          ← Reset all tool passwords
```

---

## 📊 Results

Running against DVWA (Damn Vulnerable Web Application):

| Tool | Severity | Count |
|---|---|---|
| Trivy | HIGH CVEs | 145 |
| SonarQube | Security Issues | 8 |
| OWASP ZAP | DAST Findings | 21 |
| Nikto | Server Issues | 11 |
| Dep-Check | Library CVEs | 6 |
| Headers | Missing Headers | 5 |
| **Total** | **All** | **965** |

---

## 🔒 Security Hardening Included

- SSH on custom port, key-only, no root login
- UFW firewall — deny all by default
- Fail2Ban — brute force protection
- Docker daemon hardened
- All version headers hidden
- System banners cleared
- Automatic security updates
- Audit logging enabled

---

## 🛣️ Roadmap / Future Scope

- [ ] Elastic IPs — eliminate dynamic IP problem
- [ ] Automated security gate — block deploy on Critical findings
- [ ] Gitleaks — secret scanning on every commit
- [ ] Slack/Email notifications
- [ ] ZAP authenticated scanning
- [ ] Terraform Infrastructure as Code
- [ ] AI-powered false positive reduction (SENTINEL)
- [ ] Developer DNA security profiling
- [ ] Real-time CVE correlation engine

---

## 📖 Documentation

| Document | Description |
|---|---|
| [Installation Guide](docs/INSTALLATION.md) | Complete setup from scratch |
| [Configuration](docs/CONFIGURATION.md) | All .env options explained |
| [Tools Guide](docs/TOOLS.md) | Each security tool explained |
| [OWASP Coverage](docs/OWASP_COVERAGE.md) | How each A01-A10 is covered |
| [Hardening Guide](docs/HARDENING.md) | Security hardening steps |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and fixes |

---

## 🤝 Contributing

Pull requests are welcome. For major changes please open an issue first.

---

## 👤 Author

**Amar9340**
- GitHub: [@Amar9340](https://github.com/Amar9340)

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

<div align="center">
<b>⭐ Star this repo if it helped you!</b>
</div>
