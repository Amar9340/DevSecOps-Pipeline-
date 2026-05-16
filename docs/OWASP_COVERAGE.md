# 🛡️ OWASP Top 10 — 2021 Complete Coverage

This pipeline covers all 10 OWASP Top 10 2021 categories.

| Category | Tool | Pipeline Stage | Finding on DVWA |
|---|---|---|---|
| A01 — Broken Access Control | OWASP ZAP | Stage 8 | Directory browsing, missing auth headers |
| A02 — Cryptographic Failures | testssl.sh | Stage 6 | No HTTPS, HTTP only |
| A03 — Injection | SQLMap | Stage 7 | MySQL injection confirmed (3 types) |
| A04 — Insecure Design | SonarQube | Stage 2 | 8 security code issues |
| A05 — Security Misconfiguration | Nikto + ZAP | Stage 9 + 8 | Apache outdated, exposed dirs |
| A06 — Vulnerable Components | Trivy + DC | Stage 4 + 5 | 145 HIGH CVEs in base image |
| A07 — Auth & Session Failures | OWASP ZAP | Stage 8 | Cookie flags missing |
| A08 — Software Integrity | Docker + Trivy | Stage 3 + 4 | Container image scanned |
| A09 — Logging Failures | curl/grep | Stage 10 | 5 security headers missing |
| A10 — SSRF | OWASP ZAP | Stage 8 | ZAP active SSRF rules |

**Coverage: 10/10 = 100%**
