#!/bin/bash
set -euo pipefail

############################
# Install Secrets Store CSI Driver
############################
echo "🔐 Installing CSI Driver..."
sudo microk8s helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

sudo microk8s helm repo update

sudo microk8s helm install csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  --version 1.4.8 \
  -n kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true

############################
# Install OCI Provider
############################
echo "☁️ Installing OCI Provider..."
sudo microk8s kubectl apply -k ./infrastructure/oci-provider/
