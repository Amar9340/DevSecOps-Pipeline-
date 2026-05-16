#!/bin/bash
# Reset all tool passwords
source "$(dirname "$0")/../.env" 2>/dev/null

echo "DevSecOps — Password Reset Tool"
echo "================================"

echo ""
echo "1) SonarQube — reset to admin/admin"
sudo docker stop sonarqube && sudo docker rm sonarqube
sudo docker run -d --name sonarqube --restart unless-stopped \
  -p ${SONARQUBE_PORT:-9000}:9000 sonarqube:community
echo "   ✅ SonarQube reset — login: admin/admin"

echo ""
echo "2) DefectDojo — prompts for new password"
cd ~/django-DefectDojo
sudo docker-compose exec uwsgi python manage.py changepassword admin

echo ""
echo "3) Grafana — reset"
sudo systemctl stop grafana-server
sudo rm -f /var/lib/grafana/grafana.db /usr/share/grafana/data/grafana.db
sudo systemctl start grafana-server
sleep 5
sudo grafana-cli --homepath /usr/share/grafana \
  --config /etc/grafana/grafana.ini \
  admin reset-admin-password "${GRAFANA_ADMIN_PASSWORD:-admin}" 2>/dev/null
echo "   ✅ Grafana reset — login: admin/${GRAFANA_ADMIN_PASSWORD:-admin}"

echo ""
echo "4) DVWA — reset database"
sudo docker restart dvwa
echo "   ✅ DVWA reset — go to http://VM_IP:8888/setup.php"
echo "   Click: Create / Reset Database"
echo "   Login: admin/password"

echo ""
echo "5) Jenkins"
echo "   Password is set during browser setup"
echo "   Initial password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'already configured')"
