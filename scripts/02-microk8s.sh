#!/bin/bash
set -euo pipefail

############################
# Install MicroK8s
############################
echo "📦 Installing MicroK8s..."
sudo snap install microk8s --classic --channel=1.29/stable || true
sudo microk8s start
sudo microk8s status --wait-ready
sudo microk8s enable dns
sudo microk8s enable hostpath-storage
sudo microk8s enable metrics-server
sudo microk8s enable helm
