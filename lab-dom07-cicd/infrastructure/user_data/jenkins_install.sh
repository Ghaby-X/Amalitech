#!/bin/bash
set -euo pipefail

dnf update -y

# java - required by current jenkins lts
dnf install -y java-21-amazon-corretto

# jenkins lts repo + package
curl -fsSL https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins git

# node - install/test stages run directly on this host
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# docker - build/push/deploy stages shell out to it
dnf install -y docker
systemctl enable --now docker
usermod -aG docker jenkins

systemctl enable --now jenkins
