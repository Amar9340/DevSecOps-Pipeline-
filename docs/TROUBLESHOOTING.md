# 🔧 Troubleshooting Guide

---

## Jenkins

**Not accessible on port 8080**
```bash
sudo systemctl status jenkins
sudo systemctl restart jenkins
sudo journalctl -u jenkins -n 50
```

**Docker permission denied in pipeline**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**GPG key error during install**
```bash
sudo apt-key adv --keyserver keyserver.ubuntu.com \
  --recv-keys 7198F4B714ABFC68
```

**Initial password location**
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## SonarQube

**Not starting**
```bash
sudo docker logs sonarqube --tail 50
sudo docker restart sonarqube
sleep 60
curl -s http://localhost:9000/api/system/status
```

**Forgot password — reset without data loss**
```bash
sudo docker exec -it sonarqube bash
curl -u admin:admin \
  http://localhost:9000/api/users/change_password \
  -d "login=admin&previousPassword=admin&password=NewPass@123"
exit
```

**Hard reset (wipes scan history)**
```bash
sudo docker stop sonarqube && sudo docker rm sonarqube
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:community
# Login: admin/admin
```

---

## DefectDojo

**Containers not starting**
```bash
cd ~/django-DefectDojo
sudo docker-compose ps
sudo docker-compose up -d
sudo docker-compose logs --tail 20
```

**Reset admin password**
```bash
cd ~/django-DefectDojo
sudo docker-compose exec uwsgi python manage.py changepassword admin
```

**Port conflict with Jenkins**
```bash
# DefectDojo should be on 8090 not 8080
cd ~/django-DefectDojo
sudo docker-compose down
sed -i 's/"8080:8080"/"8090:8080"/g' docker-compose.yml
sudo docker-compose up -d
```

---

## Grafana

**Login failed**
```bash
sudo systemctl stop grafana-server
sudo rm /var/lib/grafana/grafana.db
sudo rm /usr/share/grafana/data/grafana.db 2>/dev/null
sudo systemctl start grafana-server
sleep 10
# Login: admin/admin
```

**Reset password via CLI**
```bash
sudo grafana-cli \
  --homepath /usr/share/grafana \
  --config /etc/grafana/grafana.ini \
  admin reset-admin-password NewPassword@123
```

---

## DVWA

**Not accessible**
```bash
sudo docker restart dvwa
sudo docker logs dvwa --tail 20
```

**Database not initialized**
```
Browser: http://192.168.56.101:8888/setup.php
Click: Create / Reset Database
```

---

## Pipeline Issues

**ZAP stage fails pipeline**
```groovy
// Ensure || true is at end of ZAP command
sh '... zap-full-scan.py ... || true'
```

**Unicode error in Jenkinsfile**
```
# When editing Jenkinsfile in browser:
Use Ctrl+Shift+V instead of Ctrl+V
# This pastes plain text without hidden Unicode chars
```

**IP changed after restart**
```bash
# Check new IPs
ip addr show

# Update Jenkinsfile environment block:
SONAR_HOST  = 'http://NEW_IP:9000'
DOJO_URL    = 'http://NEW_IP:8090'
TARGET_URL  = 'http://NEW_IP:8888'

# Update Jenkins SonarQube config:
# Manage Jenkins → System → SonarQube servers → Update URL
```

**DefectDojo upload fails**
```bash
# Check engagement ID
# DefectDojo → Engagements → check URL shows /engagement/1/
# Make sure ENGAGEMENT_ID=1 in Jenkinsfile

# Test API manually
curl -H "Authorization: Token YOUR_TOKEN" \
  http://192.168.56.101:8090/api/v2/engagements/
```

---

## Check All Services at Once

```bash
bash scripts/status.sh
```

Expected output:
```
✅ Jenkins    → Active (running) on port 8080
✅ SonarQube  → Up on port 9000
✅ DefectDojo → Up on port 8090
✅ Grafana    → Active (running) on port 3000
✅ DVWA       → Up on port 8888
```

---

## Check Open Ports

```bash
sudo ss -tlnp | grep -E "8080|9000|8090|3000|8888|2277"
```

All 6 ports should appear.

---

## Full Reset (Nuclear Option)

Only if everything is broken beyond repair:

```bash
# Stop everything
sudo systemctl stop jenkins grafana-server
sudo docker stop $(sudo docker ps -q)
sudo docker rm $(sudo docker ps -aq)

# Re-run deploy
cd ~/devsecops-pipeline
sudo bash scripts/deploy.sh
```
