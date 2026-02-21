#!/bin/bash
set -euo pipefail

echo "### 🚀 Bootstrap MicroK8s Cluster ###"

./scripts/01-system.sh
./scripts/02-microk8s.sh
./scripts/03-storage.sh
./scripts/04-secrets.sh
./scripts/05-monitoring.sh
./scripts/06-argocd.sh
./scripts/07-apps.sh
./scripts/08-runtime.sh

echo "### ✅ Bootstrap Complete! ###"