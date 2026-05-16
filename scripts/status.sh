#!/bin/bash
# Check status of all DevSecOps services
source "$(dirname "$0")/../.env" 2>/dev/null

IP=${VM_IP:-192.168.56.101}
G='\033[0;32m' R='\033[0;31m' Y='\033[1;33m' NC='\033[0m'

check() {
  local name=$1 url=$2
  if curl -sf "$url" > /dev/null 2>&1; then
    echo -e "${G}[✅ UP  ]${NC} $name → $url"
  else
    echo -e "${R}[❌ DOWN]${NC} $name → $url"
  fi
}

svc() {
  local name=$1 service=$2
  if systemctl is-active --quiet $service; then
    echo -e "${G}[✅ UP  ]${NC} $name (systemd)"
  else
    echo -e "${R}[❌ DOWN]${NC} $name (systemd)"
  fi
}

docker_check() {
  local name=$1 container=$2
  if sudo docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo -e "${G}[✅ UP  ]${NC} $name (docker)"
  else
    echo -e "${R}[❌ DOWN]${NC} $name (docker)"
  fi
}

echo ""
echo "══════════════════════════════════════════"
echo "  DevSecOps Pipeline — Service Status"
echo "══════════════════════════════════════════"
svc        "Jenkins     " jenkins
check      "Jenkins UI  " "http://$IP:${JENKINS_PORT:-8080}"
docker_check "SonarQube  " sonarqube
check      "SonarQube   " "http://$IP:${SONARQUBE_PORT:-9000}/api/system/status"
check      "DefectDojo  " "http://$IP:${DEFECTDOJO_PORT:-8090}"
svc        "Grafana     " grafana-server
check      "Grafana UI  " "http://$IP:${GRAFANA_PORT:-3000}"
docker_check "DVWA       " dvwa
check      "DVWA        " "http://$IP:${DVWA_PORT:-8888}"
echo "══════════════════════════════════════════"
echo ""
echo "Open ports:"
sudo ss -tlnp | grep -E ":8080|:9000|:8090|:3000|:8888|:2277" | \
  awk '{print "  " $4}' | sort
echo ""
