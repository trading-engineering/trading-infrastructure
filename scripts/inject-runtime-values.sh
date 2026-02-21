#!/bin/bash
set -euo pipefail

: "${VAULT_ID:?VAULT_ID not set}"
: "${OCI_REGION:?OCI_REGION not set}"

inject_app() {
  local app_name=$1
  local spc_name=$2
  local deployment_name=$3
  local needs_region=$4

  echo "🔧 Injecting runtime values into ${app_name}..."

  PATCH=$(cat <<EOF
spec:
  source:
    kustomize:
      patches:
        - target:
            group: secrets-store.csi.x-k8s.io
            version: v1
            kind: SecretProviderClass
            name: ${spc_name}
          patch: |-
            - op: replace
              path: /spec/parameters/vaultId
              value: ${VAULT_ID}
EOF
)

  if [ "$needs_region" = "true" ]; then
    PATCH="${PATCH}
        - target:
            group: apps
            version: v1
            kind: Deployment
            name: ${deployment_name}
          patch: |-
            - op: replace
              path: /spec/template/spec/containers/0/env/0/value
              value: ${OCI_REGION}
"
  fi

  sudo microk8s kubectl patch application "${app_name}" \
    -n default \
    --type merge \
    -p "${PATCH}"

  sudo microk8s kubectl annotate application "${app_name}" \
    -n default argocd.argoproj.io/refresh=hard --overwrite
}

# -------- Apps --------

inject_app "postgres" "postgres-secret-bundle" "postgres" false
inject_app "mlflow" "mlflow-secret-bundle" "mlflow" true
inject_app "monitoring" "monitoring-secret-bundle" "monitoring" false
