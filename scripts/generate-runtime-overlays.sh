#!/bin/bash
set -euo pipefail

echo "🔧 Loading environment config..."
: "${VAULT_ID:?VAULT_ID not set}"
: "${OCI_REGION:?OCI_REGION not set}"

create_runtime_overlay() {
  local app_name=$1
  local namespace=$2

  local spc_name=${3:-}
  local needs_vault=${4:-false}

  local deployment_name=${5:-}
  local container_name=${6:-}
  local needs_region=${7:-false}

  echo "🧩 Creating runtime overlay for ${app_name}..."
  mkdir -p "apps/${app_name}/overlays/runtime"

  local file="apps/${app_name}/overlays/runtime/kustomization.yaml"

  cat > "$file" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../
EOF

  if [ "${needs_vault}" = "true" ] || [ "${needs_region}" = "true" ]; then
    echo "" >> "$file"
    echo "patches:" >> "$file"
  fi

  if [ "${needs_vault}" = "true" ]; then
    cat >> "$file" <<EOF
  - target:
      group: secrets-store.csi.x-k8s.io
      version: v1
      kind: SecretProviderClass
      name: ${spc_name}
      namespace: ${namespace}
    patch: |-
      apiVersion: secrets-store.csi.x-k8s.io/v1
      kind: SecretProviderClass
      metadata:
        name: ${spc_name}
        namespace: ${namespace}
      spec:
        parameters:
          vaultId: ${VAULT_ID}
EOF
  fi

  if [ "${needs_region}" = "true" ]; then
    cat >> "$file" <<EOF
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: ${deployment_name}
      namespace: ${namespace}
    patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: ${deployment_name}
        namespace: ${namespace}
      spec:
        template:
          spec:
            containers:
              - name: ${container_name}
                env:
                  - name: AWS_DEFAULT_REGION
                    value: ${OCI_REGION}
EOF
  fi
}

# -------- define apps here --------

create_runtime_overlay "postgres" "postgres" "postgres-secret-bundle" true "postgres" "postgres" false
create_runtime_overlay "mlflow" "mlflow" "mlflow-secret-bundle" true "mlflow" "mlflow" true
create_runtime_overlay "monitoring" "monitoring" "monitoring-secret-bundle" true "monitoring" "monitoring" false
