#!/bin/bash
set -euo pipefail

echo "🔧 Loading environment config..."
: "${VAULT_ID:?VAULT_ID not set}"
: "${OCI_REGION:?OCI_REGION not set}"

ARGO_NS="${ARGO_NS:-default}"

wait_for_app() {
  local app_name=$1
  echo "⏳ Waiting for application ${app_name} in namespace ${ARGO_NS}..."
  until sudo microk8s kubectl -n "${ARGO_NS}" get application "${app_name}" >/dev/null 2>&1; do
    sleep 2
  done
}

inject_app() {
  local app_name=$1
  local spc_name=${2:-}           # SecretProviderClass name (optional if needs_vault=false)
  local deployment_name=${3:-}    # Deployment name (optional if needs_region=false)
  local needs_vault=${4:-false}
  local needs_region=${5:-false}

  # Optional: wait for the Application to exist (comment out if you prefer "skip")
  wait_for_app "${app_name}"

  echo "🔧 Injecting runtime values into ${app_name}..."

  # Start building the YAML merge patch for the Application spec
  local PATCH
  PATCH=$(cat <<EOF
spec:
  source:
    kustomize:
      patches:
EOF
)

  # VaultID patch (JSON6902) for SecretProviderClass
  if [ "${needs_vault}" = "true" ]; then
    if [ -z "${spc_name}" ]; then
      echo "❌ spc_name is required for ${app_name} when needs_vault=true"
      exit 1
    fi

    PATCH="${PATCH}
        - target:
            group: secrets-store.csi.x-k8s.io
            version: v1
            kind: SecretProviderClass
            name: ${spc_name}
          patch: |-
            - op: replace
              path: /spec/parameters/vaultId
              value: ${VAULT_ID}
"
  fi

  # Region patch: robustly ADD env var to containers[0].env (no fragile index for env list)
  # Note: this assumes the intended container is containers[0]. If that's not true for an app,
  # we can target a different container index or split deployments.
  if [ "${needs_region}" = "true" ]; then
    if [ -z "${deployment_name}" ]; then
      echo "❌ deployment_name is required for ${app_name} when needs_region=true"
      exit 1
    fi

    PATCH="${PATCH}
        - target:
            group: apps
            version: v1
            kind: Deployment
            name: ${deployment_name}
          patch: |-
            - op: add
              path: /spec/template/spec/containers/0/env/-
              value:
                name: AWS_DEFAULT_REGION
                value: ${OCI_REGION}
"
  fi

  # If neither vault nor region is needed, do nothing
  if [ "${needs_vault}" != "true" ] && [ "${needs_region}" != "true" ]; then
    echo "ℹ️ Nothing to inject for ${app_name} (needs_vault=false, needs_region=false). Skipping."
    return 0
  fi

  # Apply patch to the ArgoCD Application
  sudo microk8s kubectl patch application "${app_name}" \
    -n "${ARGO_NS}" \
    --type merge \
    -p "${PATCH}"

  # Force ArgoCD to re-render / refresh
  sudo microk8s kubectl annotate application "${app_name}" \
    -n "${ARGO_NS}" \
    argocd.argoproj.io/refresh=hard --overwrite

  echo "✅ Injected runtime values into ${app_name}"
}

# -------- Apps --------
# inject_app <app_name> <spc_name> <deployment_name> <needs_vault> <needs_region>

inject_app "postgres"   "postgres-secret-bundle"   "postgres"   true false
inject_app "mlflow"     "mlflow-secret-bundle"     "mlflow"     true true
inject_app "monitoring" "monitoring-secret-bundle" "monitoring" true false
