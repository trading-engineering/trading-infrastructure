#!/bin/bash
set -euo pipefail

############################
# Install Argo CD
############################
echo "🚀 Installing Argo CD..."

sudo microk8s kubectl delete crd applications.argoproj.io --ignore-not-found
sudo microk8s kubectl delete crd appprojects.argoproj.io --ignore-not-found
sudo microk8s kubectl delete crd applicationsets.argoproj.io --ignore-not-found

sudo microk8s kubectl apply --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.3.0/manifests/install.yaml

echo "⏳ Waiting for ArgoCD components..."

sudo microk8s kubectl rollout status statefulset/argocd-application-controller -n default
sudo microk8s kubectl rollout status deployment/argocd-repo-server -n default
sudo microk8s kubectl rollout status deployment/argocd-server -n default

############################
# Enable Helm in Kustomize
############################
echo "🧩 Enabling Helm support..."

sudo microk8s kubectl patch configmap argocd-cm -n default \
  --type merge \
  -p '{"data":{"kustomize.buildOptions":"--enable-helm"}}'

sudo microk8s kubectl rollout restart deployment argocd-repo-server -n default

sudo microk8s kubectl rollout status deployment/argocd-repo-server -n default
