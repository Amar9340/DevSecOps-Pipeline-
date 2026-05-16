#!/bin/bash
# Start all DevSecOps services
source "$(dirname "$0")/../.env" 2>/dev/null || source ~/.env 2>/dev/null

G='\033[0;32m' C='\033[0;36m' NC='\033[0m'
log() { echo -e "${G}[✅]${NC} $1"; }
info() { echo -e "${C}[🚀]${NC} $1"; }

echo "Starting DevSecOps Pipeline..."

info "Starting Docker..."
sudo systemctl start docker

info "Starting SonarQube..."
sudo docker start sonarqube 2>/dev/null || true

info "Starting DefectDojo..."
cd ~/django-DefectDojo && sudo docker-compose up -d

info "Starting DVWA..."
sudo docker start dvwa 2>/dev/null || true

info "Starting Jenkins..."
sudo systemctl start jenkins

info "Starting Grafana..."
sudo systemctl start grafana-server

echo ""
echo "⏳ Waiting 60 seconds for services to initialize..."
sleep 60

echo ""
echo "══════════════════════════════════"
echo "  ✅ All Services Started"
echo "══════════════════════════════════"
echo "  Jenkins:    http://${VM_IP:-192.168.56.101}:${JENKINS_PORT:-8080}"
echo "  SonarQube:  http://${VM_IP:-192.168.56.101}:${SONARQUBE_PORT:-9000}"
echo "  DefectDojo: http://${VM_IP:-192.168.56.101}:${DEFECTDOJO_PORT:-8090}"
echo "  Grafana:    http://${VM_IP:-192.168.56.101}:${GRAFANA_PORT:-3000}"
echo "  DVWA:       http://${VM_IP:-192.168.56.101}:${DVWA_PORT:-8888}"
echo "══════════════════════════════════"
