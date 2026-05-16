#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#   DevSecOps Pipeline — One Command Deploy Script
#   Usage: sudo bash scripts/deploy.sh
# ═══════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/.env"

GREEN='\033[0;32m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
RED='\033[0;31m' BLUE='\033[0;34m' BOLD='\033[1m' NC='\033[0m'

log()     { echo -e "${GREEN}[✅]${NC} $1"; }
info()    { echo -e "${CYAN}[ℹ️ ]${NC} $1"; }
warn()    { echo -e "${YELLOW}[⚠️ ]${NC} $1"; }
error()   { echo -e "${RED}[❌]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}${BOLD}══ $1 ══${NC}\n"; }

[[ $EUID -ne 0 ]] && error "Run as root: sudo bash scripts/deploy.sh"

section "System Update"
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq curl wget git unzip nano net-tools \
  ca-certificates gnupg ufw fail2ban fontconfig openjdk-17-jre
log "System ready"

section "Docker"
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io
fi
curl -sL "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
cat > /etc/docker/daemon.json << 'EOF'
{"icc":false,"log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"3"},"no-new-privileges":true,"live-restore":true}
EOF
systemctl restart docker && systemctl enable docker
log "Docker $(docker --version) ready"

section "Jenkins"
wget -q -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -qq && apt-get install -y -qq jenkins
usermod -aG docker jenkins
systemctl start jenkins && systemctl enable jenkins
log "Jenkins started"

section "Security Tools"
apt-get install -y -qq sqlmap
[ ! -f /usr/local/bin/testssl.sh ] && \
  git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl && \
  ln -sf /opt/testssl/testssl.sh /usr/local/bin/testssl.sh
[ ! -f /usr/local/bin/dependency-check.sh ] && \
  wget -q "https://github.com/jeremylong/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip" -O /tmp/dc.zip && \
  unzip -q /tmp/dc.zip -d /opt && rm /tmp/dc.zip && \
  ln -sf /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check.sh
log "Security tools installed"

section "SonarQube"
docker run -d --name sonarqube --restart unless-stopped \
  -p $SONARQUBE_PORT:9000 sonarqube:community 2>/dev/null || \
  docker start sonarqube
log "SonarQube started"

section "DefectDojo"
[ ! -d ~/django-DefectDojo ] && \
  git clone https://github.com/DefectDojo/django-DefectDojo.git ~/django-DefectDojo
cd ~/django-DefectDojo
sed -i "s/\"8080:8080\"/\"$DEFECTDOJO_PORT:8080\"/g" docker-compose.yml 2>/dev/null
docker-compose up -d
log "DefectDojo started"

section "DVWA"
docker run -d --name dvwa --restart unless-stopped \
  -p $DVWA_PORT:80 vulnerables/web-dvwa 2>/dev/null || \
  docker start dvwa
log "DVWA started"

section "Grafana"
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] \
  https://apt.grafana.com stable main" | \
  tee /etc/apt/sources.list.d/grafana.list
apt-get update -qq && apt-get install -y -qq grafana
systemctl start grafana-server && systemctl enable grafana-server
sleep 5
grafana-cli --homepath /usr/share/grafana \
  --config /etc/grafana/grafana.ini \
  admin reset-admin-password "$GRAFANA_ADMIN_PASSWORD" 2>/dev/null || true
log "Grafana started"

section "Security Hardening"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat > /etc/ssh/sshd_config << EOF
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication yes
MaxAuthTries 3
PermitEmptyPasswords no
X11Forwarding no
Banner none
PrintMotd no
EOF
systemctl restart sshd
truncate -s 0 /etc/motd /etc/issue /etc/issue.net
ufw --force reset
ufw default deny incoming && ufw default allow outgoing
ufw allow $SSH_PORT/tcp
ufw allow from 192.168.56.0/24 to any port $JENKINS_PORT
ufw allow from 192.168.56.0/24 to any port $SONARQUBE_PORT
ufw allow from 192.168.56.0/24 to any port $DEFECTDOJO_PORT
ufw allow from 192.168.56.0/24 to any port $GRAFANA_PORT
ufw allow from 192.168.56.0/24 to any port $DVWA_PORT
ufw --force enable
log "Security hardening applied"

section "Startup Script"
cp "$SCRIPT_DIR/scripts/start.sh" ~/start.sh
chmod +x ~/start.sh
log "Startup script created"

section "DONE"
JPASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null)
echo -e "${GREEN}${BOLD}"
echo "  Jenkins:    http://$VM_IP:$JENKINS_PORT"
echo "  SonarQube:  http://$VM_IP:$SONARQUBE_PORT"
echo "  DefectDojo: http://$VM_IP:$DEFECTDOJO_PORT"
echo "  Grafana:    http://$VM_IP:$GRAFANA_PORT"
echo "  DVWA:       http://$VM_IP:$DVWA_PORT"
echo ""
echo "  Jenkins Initial Password: $JPASS"
echo -e "${NC}"
echo "  ⚠️  See docs/INSTALLATION.md for the 5 manual browser steps"
