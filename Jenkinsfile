// ═══════════════════════════════════════════════════════════════
//   DevSecOps CI/CD Pipeline — Complete Jenkinsfile
//   Author: Amar9340 | Rayat Bahra University, Mohali
//   OWASP Top 10 2021 — All 10 Categories Covered
//   11 Stages | 7 Security Tools | 0 Licensing Cost
// ═══════════════════════════════════════════════════════════════

pipeline {
    agent any

    // ── Environment Variables ─────────────────────────────────
    // All sensitive values loaded from Jenkins Credential Manager
    // Never hardcode tokens here — use credentials() function
    environment {
        SONAR_TOKEN    = credentials('sonarqube-token')
        DOJO_TOKEN     = credentials('defectdojo-token')

        // Update these when VM IP changes
        SONAR_HOST     = 'http://192.168.56.101:9000'
        DOJO_URL       = 'http://192.168.56.101:8090'
        TARGET_URL     = 'http://192.168.56.101:8888'

        ENGAGEMENT_ID  = '1'
        PROJECT_KEY    = 'DVWA'
    }

    stages {

        // ─────────────────────────────────────────────────────
        // STAGE 1 — Clone Source Code
        // ─────────────────────────────────────────────────────
        stage('Clone Code') {
            steps {
                echo '📥 Cloning source code from GitHub...'
                git branch: 'master',
                    credentialsId: 'github-credentials',
                    url: 'https://github.com/Amar9340/DVWA'
                echo '✅ Code cloned successfully'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 2 — Static Application Security Testing (SAST)
        // OWASP: A04 (Insecure Design) + A01 (Broken Access)
        // Tool: SonarQube Community Edition
        // Output: SonarQube dashboard
        // ─────────────────────────────────────────────────────
        stage('A04+A01: SonarQube SAST') {
            steps {
                echo '🔍 Running SonarQube static analysis...'
                withSonarQubeEnv('sonarqube') {
                    sh '''
                        docker run --rm \
                        -e SONAR_HOST_URL=$SONAR_HOST \
                        -e SONAR_TOKEN=$SONAR_TOKEN \
                        -v $(pwd):/usr/src \
                        sonarsource/sonar-scanner-cli \
                        -Dsonar.projectKey=$PROJECT_KEY \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=**/vendor/**,**/node_modules/** \
                        || true
                    '''
                }
                echo '✅ SonarQube analysis complete'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 3 — Docker Image Build
        // OWASP: A08 (Software & Data Integrity Failures)
        // Tool: Docker CE
        // Output: dvwa:latest image in local registry
        // ─────────────────────────────────────────────────────
        stage('A08: Docker Build') {
            steps {
                echo '🐳 Building Docker image...'
                sh 'docker build -t dvwa:latest .'
                echo '✅ Docker image built: dvwa:latest'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 4 — Container Vulnerability Scanning
        // OWASP: A06 (Vulnerable & Outdated Components)
        // Tool: Trivy by Aqua Security
        // Output: trivy-report.json
        // ─────────────────────────────────────────────────────
        stage('A06: Trivy Container Scan') {
            steps {
                echo '🛡️ Scanning container image for CVEs...'
                sh '''
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v $(pwd):/output \
                    aquasec/trivy:latest image \
                    --exit-code 0 \
                    --severity HIGH,CRITICAL \
                    --format json \
                    --output /output/trivy-report.json \
                    dvwa:latest
                '''
                echo '✅ Trivy scan complete → trivy-report.json'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 5 — Software Composition Analysis (SCA)
        // OWASP: A06 (Vulnerable & Outdated Components)
        // Tool: OWASP Dependency Check 9.0.9
        // Output: dc-report/dependency-check-report.json
        // ─────────────────────────────────────────────────────
        stage('A06: Dependency Check') {
            steps {
                echo '📦 Scanning dependencies for CVEs...'
                sh '''
                    dependency-check.sh \
                    --project DVWA \
                    --scan $(pwd) \
                    --format JSON \
                    --out $(pwd)/dc-report \
                    --disableYarnAudit \
                    --disableNodeAudit || true
                '''
                echo '✅ Dependency check complete → dc-report/'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 6 — TLS/SSL Configuration Audit
        // OWASP: A02 (Cryptographic Failures)
        // Tool: testssl.sh 3.3dev
        // Output: testssl-report.json
        // ─────────────────────────────────────────────────────
        stage('A02: TLS/SSL Scan') {
            steps {
                echo '🔐 Auditing TLS/SSL configuration...'
                sh '''
                    testssl.sh \
                    --jsonfile $(pwd)/testssl-report.json \
                    --severity HIGH \
                    --quiet \
                    $TARGET_URL || true
                '''
                echo '✅ TLS/SSL audit complete → testssl-report.json'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 7 — SQL Injection Testing
        // OWASP: A03 (Injection)
        // Tool: SQLMap 1.6.4
        // Output: sqlmap-output/ directory
        // ─────────────────────────────────────────────────────
        stage('A03: SQL Injection') {
            steps {
                echo '💉 Testing for SQL injection vulnerabilities...'
                sh '''
                    sqlmap \
                    -u "$TARGET_URL/vulnerabilities/sqli/?id=1&Submit=Submit" \
                    --cookie="PHPSESSID=abc123; security=low" \
                    --batch \
                    --level=3 \
                    --risk=2 \
                    --output-dir=$(pwd)/sqlmap-output || true
                '''
                echo '✅ SQL injection test complete → sqlmap-output/'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 8 — Dynamic Application Security Testing (DAST)
        // OWASP: A01 (Broken Access Control)
        //         A05 (Security Misconfiguration)
        //         A07 (Identification & Auth Failures)
        //         A10 (SSRF) via active scan rules
        // Tool: OWASP ZAP Stable
        // Output: zap-report.xml, zap-report.html, zap-report.json
        // Note: || true because ZAP exits 3 when findings exist
        //        --user root needed for volume write permissions
        // ─────────────────────────────────────────────────────
        stage('A01+A05+A07: OWASP ZAP DAST') {
            steps {
                echo '⚡ Running OWASP ZAP full dynamic scan...'
                sh '''
                    docker run --rm \
                    --user root \
                    -v $(pwd):/zap/wrk/:rw \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-full-scan.py \
                    -t $TARGET_URL \
                    -r zap-report.html \
                    -J zap-report.json \
                    -x zap-report.xml \
                    -I || true
                '''
                echo '✅ ZAP scan complete → zap-report.xml'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 9 — Web Server Misconfiguration Scanning
        // OWASP: A05 (Security Misconfiguration)
        // Tool: Nikto 2.1.5
        // Output: nikto-report.xml
        // Note: --user root needed for volume write permissions
        // ─────────────────────────────────────────────────────
        stage('A05: Nikto Server Scan') {
            steps {
                echo '🖥️ Scanning server for misconfigurations...'
                sh '''
                    docker run --rm \
                    --user root \
                    -v $(pwd):/report \
                    secfigo/nikto:latest \
                    -h $TARGET_URL \
                    -o /report/nikto-report.xml \
                    -Format xml || true
                '''
                echo '✅ Nikto scan complete → nikto-report.xml'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 10 — HTTP Security Headers Verification
        // OWASP: A09 (Security Logging & Monitoring Failures)
        // Tool: curl + grep (bash)
        // Output: headers-report.txt
        // Checks: X-Frame-Options, X-Content-Type-Options,
        //         Content-Security-Policy, HSTS, Referrer-Policy
        // ─────────────────────────────────────────────────────
        stage('A09: Security Headers Check') {
            steps {
                echo '📋 Checking HTTP security headers...'
                sh '''
                    curl -s -I $TARGET_URL > $(pwd)/headers-report.txt

                    echo "=== Security Headers Analysis ===" \
                      >> $(pwd)/headers-report.txt

                    grep -i "x-frame-options" $(pwd)/headers-report.txt \
                      && echo "✅ X-Frame-Options: PRESENT" \
                      || echo "❌ MISSING: X-Frame-Options" \
                      >> $(pwd)/headers-report.txt

                    grep -i "x-content-type-options" $(pwd)/headers-report.txt \
                      && echo "✅ X-Content-Type-Options: PRESENT" \
                      || echo "❌ MISSING: X-Content-Type-Options" \
                      >> $(pwd)/headers-report.txt

                    grep -i "content-security-policy" $(pwd)/headers-report.txt \
                      && echo "✅ Content-Security-Policy: PRESENT" \
                      || echo "❌ MISSING: Content-Security-Policy" \
                      >> $(pwd)/headers-report.txt

                    grep -i "strict-transport-security" $(pwd)/headers-report.txt \
                      && echo "✅ Strict-Transport-Security: PRESENT" \
                      || echo "❌ MISSING: Strict-Transport-Security" \
                      >> $(pwd)/headers-report.txt

                    grep -i "referrer-policy" $(pwd)/headers-report.txt \
                      && echo "✅ Referrer-Policy: PRESENT" \
                      || echo "❌ MISSING: Referrer-Policy" \
                      >> $(pwd)/headers-report.txt

                    echo "==================================="
                    cat $(pwd)/headers-report.txt
                '''
                echo '✅ Headers check complete → headers-report.txt'
            }
        }

        // ─────────────────────────────────────────────────────
        // STAGE 11 — Upload All Findings to DefectDojo
        // Tool: DefectDojo REST API v2
        // Reports: Trivy JSON, ZAP XML, Nikto XML, DC JSON
        // ─────────────────────────────────────────────────────
        stage('Upload to DefectDojo') {
            steps {
                echo '⬆️ Uploading all findings to DefectDojo...'
                sh '''
                    echo "--- Uploading Trivy Container Scan ---"
                    curl -s -X POST $DOJO_URL/api/v2/import-scan/ \
                    -H "Authorization: Token $DOJO_TOKEN" \
                    -F "scan_type=Trivy Scan" \
                    -F "engagement=$ENGAGEMENT_ID" \
                    -F "file=@trivy-report.json" \
                    -F "active=true" \
                    -F "verified=false"

                    echo ""
                    echo "--- Uploading ZAP DAST Scan ---"
                    curl -s -X POST $DOJO_URL/api/v2/import-scan/ \
                    -H "Authorization: Token $DOJO_TOKEN" \
                    -F "scan_type=ZAP Scan" \
                    -F "engagement=$ENGAGEMENT_ID" \
                    -F "file=@zap-report.xml" \
                    -F "active=true" \
                    -F "verified=false"

                    echo ""
                    echo "--- Uploading Nikto Server Scan ---"
                    curl -s -X POST $DOJO_URL/api/v2/import-scan/ \
                    -H "Authorization: Token $DOJO_TOKEN" \
                    -F "scan_type=Nikto Scan" \
                    -F "engagement=$ENGAGEMENT_ID" \
                    -F "file=@nikto-report.xml" \
                    -F "active=true" \
                    -F "verified=false"

                    echo ""
                    echo "--- Uploading Dependency Check Scan ---"
                    curl -s -X POST $DOJO_URL/api/v2/import-scan/ \
                    -H "Authorization: Token $DOJO_TOKEN" \
                    -F "scan_type=Dependency Check Scan" \
                    -F "engagement=$ENGAGEMENT_ID" \
                    -F "file=@dc-report/dependency-check-report.json" \
                    -F "active=true" \
                    -F "verified=false" || true

                    echo ""
                    echo "✅ All findings uploaded to DefectDojo"
                '''
            }
        }
    }

    // ── Post Build Actions ────────────────────────────────────
    post {
        always {
            echo '═══════════════════════════════════'
            echo '  OWASP Top 10 Pipeline Finished!'
            echo '═══════════════════════════════════'
        }
        success {
            echo '✅ All stages completed successfully'
            echo '📊 Check DefectDojo for consolidated findings'
        }
        failure {
            echo '❌ Pipeline failed — check console output above'
        }
    }
}
