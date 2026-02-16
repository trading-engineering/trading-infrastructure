# Trading Infrastructure – GitOps Kubernetes Stack (MicroK8s + Argo CD)

This repository provisions cloud infrastructure for a complete quantitative research & backtesting platform on a single-node MicroK8s cluster using GitOps via Argo CD in Oracle Cloud Infrastructure. The cluster is bootstrapped once and all Kubernetes workloads are managed declaratively via Argo CD.

---

## 🧰 Core Stack

- [MicroK8s](https://microk8s.io) (Kubernetes distribution)
- [Argo CD](https://argo-cd.readthedocs.io) (GitOps continuous delivery)
- [PostgreSQL](https://www.postgresql.org) (metadata & experiment storage)
- [MLflow](https://mlflow.org) (experiment tracking & model registry)
- [Prometheus](https://prometheus.io) + [Grafana](https://grafana.com) (monitoring & observability)
- [Argo Workflows](https://argoproj.github.io/workflows/) (batch & pipeline execution)
- [Oracle Cloud Infrastructure](https://cloud.oracle.com) (compute, networking, secrets, storage)

---

## 🏗 Architecture Overview

**Host Layer (Bootstrap)**

- MicroK8s
- Secrets Store CSI Driver
- OCI Secrets Store Provider using a [custom multi-arch image](https://github.com/trading-engineering/oci-secrets-store-csi-driver-provider/pkgs/container/oci-secrets-store-csi-driver-provider)
- Argo CD
- Scratch Block Volume formatting & mount

**Cluster Layer (Argo CD managed)**

- PostgreSQL
- MLflow
- Monitoring (Prometheus + Grafana)
- Argo Workflows
- Scratch PersistentVolume

---

## 📁 Repository Structure

```
apps/
  mlflow/
  postgres/
  monitoring/
  argowf/
  scratch/

argocd/
  mlflow-app.yaml
  postgres-app.yaml
  monitoring-app.yaml
  argowf-app.yaml
  scratch-app.yaml

infrastructure/
  oci-provider/
    provider.yaml

scripts/
  bootstrap-cluster.sh
```

---

## 🔧 Installation (Fresh VM)

### 1️⃣ Requirements

- Ubuntu VM
- Attached Block Volume for Scratch (`/dev/oracleoci/oraclevds`)
- OCI Instance Principal configured
- This repository cloned onto the VM
- OCI Vault + predefined secrets

### 2️⃣ Environment Configuration

Before bootstrapping the cluster, create a `.env` file in the repository root:

```bash
cp .env.example .env
```

Set the required values:

```env
VAULT_ID=ocid1.vault.oc1.eu-frankfurt-1.xxxxx
OCI_REGION=eu-frankfurt-1
```

Load the environment and run bootstrap:

```bash
set -a
source .env
set +a
```

### 3️⃣ Bootstrap the Cluster

> ⚠ The bootstrap script is one-shot only.
> Run on a fresh VM or do a [full reset](#-full-reset).
> Re-running on existing cluster is not supported.
> For changes use Argo CD / GitOps.

```bash
chmod +x scripts/bootstrap-cluster.sh
./scripts/bootstrap-cluster.sh
```

This installs:

- MicroK8s
- CSI Driver
- OCI Provider
- Argo CD

And deploys:

- PostgreSQL
- MLflow
- Monitoring
- Argo Workflows
- Scratch PV/PVC

---

## 🌐 Accessing Services

```bash
Host vps
    HostName <IP>
    User ubuntu
    IdentityFile ~/.ssh/<key>
    LocalForward 30007 localhost:30007   # Grafana
    LocalForward 32120 localhost:32120   # Argo Workflows
    LocalForward 30090 localhost:30090   # Prometheus
    LocalForward 30500 localhost:30500   # MLflow
```

Kubernetes services are exposed as NodePorts internally on the VM.

However:

- Only SSH (port 22) is allowed at the OCI network level (NSGs).
- All service ports (Grafana, Prometheus, MLflow, Argo Workflows) are blocked externally.
- Access is performed exclusively via SSH local port forwarding.

This ensures services are reachable for development while not publicly exposed.

---

## 🔄 Updating the Platform

1. Modify YAML/Helm values in `apps/<component>/`
2. Commit & push
3. Argo CD auto-syncs

No manual kubectl required.

---

## 💾 Storage Model

This platform uses a simple and explicit local storage layout:

#### Boot Volume (VM Root Disk)

- ~47 GB (minimum OCI size)
- Hosts:

  - Operating system
  - Kubernetes system data
  - PostgreSQL database (MLflow metadata)

MLflow persists all experiment metadata in the local PostgreSQL instance backed by the VM boot volume.

#### Scratch Block Volume

- 153 GB (≈142.5 GiB, due to GB/GiB unit difference)
- Mounted at:

```
/mnt/scratch
```

Intended for short-lived and data-heavy workloads:

- Backtesting data
- Research artifacts
- Large intermediate datasets

Exposed to Kubernetes via PersistentVolume/PersistentVolumeClaim.

⚠ Single-node only (`hostPath` based).

---

## 📊 Monitoring Persistence

Prometheus runs with **ephemeral local storage by default**.

- Metrics are stored inside the Prometheus pod filesystem
- No PersistentVolume is configured
- Data is lost on pod restart or node reboot

This is intentional for lightweight research infrastructure and can be extended with persistent storage if long-term metrics retention is required.

### ⚠ Storage Monitoring

Because metrics are stored locally, regular disk usage checks are recommended to avoid unexpected storage exhaustion.

Example commands:

```bash
df -h /
sudo du -h --max-depth=1 /var/snap/microk8s/common/var/
```

These help track overall disk space and identify directories consuming the most storage.

---

## 🔐 OCI Secrets Integration (Required)

This platform depends on OCI Vault for all sensitive configuration.

Requirements:

- OCI Vault must exist
- Secrets must be created in advance
- Secret names must match the values referenced in Helm/YAML files

Secrets are retrieved using:

- Secrets Store CSI Driver
- OCI Provider (custom multi-arch image)
- Instance Principal authentication

Secrets are defined via `SecretProviderClass` in application directories.

No secrets are stored in Git.

---

## ☁️ Why Oracle Cloud Infrastructure?

OCI is used primarily for its generous ARM free tier:

- 4 vCPU ARM VM
- 24 GB RAM
- ~200 GB free storage (boot + block volume)

This makes it ideal for:

- Single-node Kubernetes research clusters
- Persistent external storage
- Zero-cost experimentation

The VM boot volume is kept minimal (~47 GB) while all data-heavy workloads use the attached scratch block volume.

---

## 🔐 Security Model

- Public VM with OCI firewall (NSGs / Security Lists)
- Only SSH exposed
- All service ports closed externally
- Egress allowed
- Secrets in OCI Vault
- No secrets in Git

---

## 🎯 Design Principles

- GitOps-first
- Single source of truth
- No imperative workflows
- multi-arch native
- Minimal but production-grade

---

## 🔁 Reusing Scratch Block Storage

#### Old VM

```bash
sudo microk8s kubectl delete namespace scratch
sudo microk8s kubectl delete pv scratch-pv
sudo umount /mnt/scratch/
```

Detach volume.

#### New VM

1. Attach volume to same device name
2. Run bootstrap
3. PV/PVC names must match
4. Data reused automatically

---

## 🧹 Full Reset

```bash
sudo snap remove microk8s --purge
sudo rm -rf /var/snap/microk8s/
sudo rm -rf ~/.kube/
```

---

## 🏁 Final State

```
VM ready
Argo CD running
All apps deployed
Secrets from OCI Vault
Boot volume for system + database
Scratch volume for data
```

Fully reproducible. Fully declarative.
