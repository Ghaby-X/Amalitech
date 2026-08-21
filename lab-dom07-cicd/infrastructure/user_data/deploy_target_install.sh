#!/bin/bash
set -euo pipefail

dnf update -y

# install docker
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
