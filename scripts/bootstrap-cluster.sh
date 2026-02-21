#!/bin/bash
set -euo pipefail

echo "### 🚀 Bootstrap MicroK8s Cluster ###"

echo "🧩 Generating runtime overlays..."
./scripts/generate-runtime-overlays.sh

############################
# Flush iptables for MicroK8s
############################
echo "🧹 Flushing iptables..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

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

############################
# Prepare Scratch Volume
############################
echo "💾 Preparing scratch disk..."

DEVICE="/dev/oracleoci/oraclevds"
MOUNTPOINT="/mnt/scratch"

if [ ! -b "$DEVICE" ]; then
  echo "❌ Device $DEVICE not found"
  exit 1
fi

if ! sudo blkid "$DEVICE" >/dev/null 2>&1; then
  echo "📀 Formatting scratch disk..."
  sudo mkfs.ext4 "$DEVICE"
fi

sudo mkdir -p "$MOUNTPOINT"

if ! mountpoint -q "$MOUNTPOINT"; then
  sudo mount "$DEVICE" "$MOUNTPOINT"
fi

sudo mkdir -p "$MOUNTPOINT/data"
sudo chown -R 1000:1000 "$MOUNTPOINT/data"

if ! grep -q "$DEVICE" /etc/fstab; then
  echo "$DEVICE $MOUNTPOINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
fi

echo "✅ Scratch volume ready"

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

############################
# Install Prometheus Operator CRDs (REQUIRED)
############################
echo "📊 Installing Prometheus CRDs..."

CRD_BASE="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.76.1/example/prometheus-operator-crd"

# Delete if partially broken
sudo microk8s kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found
sudo microk8s kubectl delete crd alertmanagers.monitoring.coreos.com --ignore-not-found
sudo microk8s kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found
sudo microk8s kubectl delete crd podmonitors.monitoring.coreos.com --ignore-not-found

# IMPORTANT: use create (NOT apply)
sudo microk8s kubectl create -f $CRD_BASE/monitoring.coreos.com_prometheuses.yaml
sudo microk8s kubectl create -f $CRD_BASE/monitoring.coreos.com_alertmanagers.yaml
sudo microk8s kubectl create -f $CRD_BASE/monitoring.coreos.com_servicemonitors.yaml
sudo microk8s kubectl create -f $CRD_BASE/monitoring.coreos.com_podmonitors.yaml

echo "✅ Prometheus CRDs installed"

############################
# Install Argo CD
############################
echo "🚀 Installing Argo CD..."

# remove old CRDs just in case
sudo microk8s kubectl delete crd applications.argoproj.io --ignore-not-found
sudo microk8s kubectl delete crd appprojects.argoproj.io --ignore-not-found
sudo microk8s kubectl delete crd applicationsets.argoproj.io --ignore-not-found

# apply server-side
sudo microk8s kubectl apply --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.3.0/manifests/install.yaml

############################
# Enable Helm in Kustomize (CRITICAL)
############################
echo "🧩 Enabling Helm support for ArgoCD Kustomize..."

sudo microk8s kubectl patch configmap argocd-cm -n default \
  --type merge \
  -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'

# Reload ArgoCD to pick up config
sudo microk8s kubectl rollout restart deployment argocd-repo-server -n default
sudo microk8s kubectl rollout restart deployment argocd-server -n default

############################
# Register Applications
############################
echo "🔗 Applying Argo Applications..."
sudo microk8s kubectl apply -f ./argocd/

echo "### ✅ Bootstrap Complete! ###"
