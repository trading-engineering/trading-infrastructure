#!/bin/bash
set -euo pipefail

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
