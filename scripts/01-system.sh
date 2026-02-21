#!/bin/bash
set -euo pipefail

echo "🔧 Loading environment config..."
: "${VAULT_ID:?VAULT_ID not set}"
: "${OCI_REGION:?OCI_REGION not set}"

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
