# Contributing

Thank you for your interest in contributing!

This repository focuses on cloud trading infrastructure.
Contributions should preserve clarity, explicitness and reproducibility.

## Design Principles

- GitOps-first
- No secrets in Git (ever)
- Everything must be declarative
- Keep changes minimal and documented
- Single source of truth
- No imperative workflows
- multi-arch native
- Minimal but production-grade

## Workflow

1. Fork the repository
2. Create a feature branch
3. Commit small, logical changes
4. Open a Pull Request with clear description

## Commit Style

Use clear messages:

feat: add monitoring overlay  
fix: correct SecretProviderClass parameters  
docs: update bootstrap instructions  

## Testing

Before submitting:

- kustomize build must succeed
- YAML must be valid
