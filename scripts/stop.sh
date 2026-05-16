#!/bin/bash
# Stop all DevSecOps services
echo "Stopping DevSecOps Pipeline..."

sudo systemctl stop jenkins
sudo systemctl stop grafana-server
cd ~/django-DefectDojo && sudo docker-compose down
sudo docker stop sonarqube dvwa 2>/dev/null || true

echo "✅ All services stopped"
echo "💡 To save AWS/hosting costs — you can now stop/snapshot the VM"
