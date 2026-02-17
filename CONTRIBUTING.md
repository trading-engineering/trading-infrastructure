# Contributing

Thank you for your interest in contributing!

## Principles

- No secrets in Git (ever)
- Everything must be declarative
- GitOps first — no manual kubectl workflows
- Keep changes minimal and documented

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
