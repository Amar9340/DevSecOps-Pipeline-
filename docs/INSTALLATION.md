# 📦 Installation Guide

Complete step-by-step installation on a fresh Ubuntu 22.04 VM.

---

## Prerequisites

### VirtualBox VM Settings
```
RAM:     12288 MB (12 GB minimum)
CPU:     4 cores
Storage: 60 GB
OS:      Ubuntu 22.04 LTS Server
Network Adapter 1: NAT
Network Adapter 2: Host-Only (vboxnet0)
```

### VirtualBox Host-Only Network
```
File → Host Network Manager → Create
  IPv4: 192.168.56.1
  Mask: 255.255.255.0
  DHCP: Enabled
```

---

## Option A — Automated (Recommended)

```bash
# 1. Clone repo
git clone https://github.com/Amar9340/devsecops-pipeline.git
cd devsecops-pipeline

# 2. Configure
cp .env.example .env
nano .env   # Set VM_IP and GITHUB_PAT at minimum

# 3. Deploy
sudo bash scripts/deploy.sh
```

Wait 15 minutes. Done.

---

## Option B — Manual Installation

### Step 1 — System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip nano net-tools \
  ca-certificates gnupg ufw fail2ban
```

### Step 2 — Static IP
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.56.101/24
      nameservers:
        addresses: [8.8.8.8]
```
```bash
sudo netplan apply
```

### Step 3 — Docker
```bash
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker Compose
sudo curl -L \
  "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 4 — Jenkins
```bash
sudo apt install -y fontconfig openjdk-17-jre
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install -y jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Step 5 — Security Tools
```bash
# SQLMap
sudo apt install -y sqlmap

# testssl.sh
git clone --depth 1 https://github.com/drwetter/testssl.sh.git ~/testssl.sh
sudo ln -s ~/testssl.sh/testssl.sh /usr/local/bin/testssl.sh

# OWASP Dependency Check
wget https://github.com/jeremylong/DependencyCheck/releases/download/v9.0.9/dependency-check-9.0.9-release.zip
unzip dependency-check-9.0.9-release.zip
sudo ln -s ~/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check.sh
```

### Step 6 — SonarQube
```bash
sudo docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:community
```

### Step 7 — DefectDojo
```bash
git clone https://github.com/DefectDojo/django-DefectDojo.git ~/django-DefectDojo
cd ~/django-DefectDojo
# Change port from 8080 to 8090
sed -i 's/"8080:8080"/"8090:8080"/g' docker-compose.yml
sudo docker-compose up -d
```

### Step 8 — DVWA
```bash
sudo docker run -d \
  --name dvwa \
  --restart unless-stopped \
  -p 8888:80 \
  vulnerables/web-dvwa
```

### Step 9 — Grafana
```bash
wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] \
  https://apt.grafana.com stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update && sudo apt-get install -y grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

---

## Post-Installation (5 Manual Steps)

### 1. Jenkins Browser Setup
```
Open: http://192.168.56.101:8080
Password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
- Install suggested plugins
- Install: SonarQube Scanner plugin
```

### 2. SonarQube — Create Project + Token
```
Open: http://192.168.56.101:9000  (admin/admin)
Projects → Create → DVWA
My Account → Security → Generate Token → jenkins-token
COPY THE TOKEN
```

### 3. DefectDojo — Product + API Key
```
Open: http://192.168.56.101:8090  (admin/defectdojo)
Products → Add → DVWA
Engagements → Add CI/CD Engagement → CI-CD Pipeline Scan
User Avatar → API v2 key
COPY THE API KEY
```

### 4. Jenkins — Add Credentials
```
Manage Jenkins → Credentials → Global → Add:
  ID: github-credentials   | GitHub PAT
  ID: sonarqube-token      | SonarQube token
  ID: defectdojo-token     | DefectDojo API key
```

### 5. GitHub Webhook
```
GitHub repo → Settings → Webhooks → Add:
  URL: http://192.168.56.101:8080/github-webhook/
  Events: push
```

---

## Access URLs

| Service | URL |
|---|---|
| Jenkins | http://192.168.56.101:8080 |
| SonarQube | http://192.168.56.101:9000 |
| DefectDojo | http://192.168.56.101:8090 |
| Grafana | http://192.168.56.101:3000 |
| DVWA | http://192.168.56.101:8888 |
