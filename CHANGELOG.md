# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and follows Semantic Versioning.

## [0.1.0] - Initial release

### Added
- MicroK8s bootstrap automation
- Argo CD GitOps deployment
- OCI Vault integration via Secrets Store CSI Driver
- PostgreSQL, MLflow, Monitoring stack
- Scratch persistent storage model

## [0.2.0] - Environment-based bootstrap configuration

### Added
- .env-driven cluster bootstrap configuration
- automatic injection of cloud-specific values into manifests
- example environment file for reproducible setup

### Changed
- removed hardcoded OCI Vault identifiers from manifests
- bootstrap process now validates required environment variables

## [Unreleased]
- CI validation pipelines
- Multi-node support
- Environment overlays
