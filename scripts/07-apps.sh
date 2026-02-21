#!/bin/bash
set -euo pipefail

############################
# Register Applications
############################
echo "🔗 Applying Argo Applications..."

sudo microk8s kubectl create namespace argocd

sudo microk8s kubectl apply -f ./argocd/

until sudo microk8s kubectl -n default get application postgres >/dev/null 2>&1; do
  sleep 2
done

until sudo microk8s kubectl -n default get application mlflow >/dev/null 2>&1; do
  sleep 2
done
