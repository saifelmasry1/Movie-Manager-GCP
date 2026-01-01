#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[1/6] Update & base packages"
apt-get update -y
apt-get install -y ca-certificates curl gnupg git gettext-base apt-transport-https lsb-release

echo "[2/6] Install Docker"
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

echo "[3/6] Install Google Cloud CLI + kubectl"
install -m 0755 -d /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update -y
apt-get install -y google-cloud-cli kubectl

echo "[4/6] Install Terraform"
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

echo "[5/6] Install Jenkins (OpenJDK 17)"
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list
apt-get update -y
apt-get install -y fontconfig openjdk-17-jre jenkins

echo "[6/6] Allow Jenkins to run Docker"
usermod -aG docker jenkins
systemctl enable --now jenkins
systemctl restart jenkins

echo "Jenkins setup done."
