# Deployment Scripts

This directory contains scripts for deploying the Stackready infrastructure to different environments.

## Prerequisites

- `kubectl` configured with access to your Kubernetes cluster
- `helm` installed (version 3.x)
- ArgoCD installed in the `argocd` namespace
- Proper RBAC permissions to deploy applications

## Scripts

### deploy-dev.sh
Deploys applications to the development environment.
```bash
cd /path/to/infrastructure
./scripts/deploy-dev.sh
```

### deploy-staging.sh
Deploys applications to the staging environment. Requires confirmation.
```bash
cd /path/to/infrastructure
./scripts/deploy-staging.sh
```

### deploy-prod.sh
Deploys applications to the production environment. Requires double confirmation.
```bash
cd /path/to/infrastructure
./scripts/deploy-prod.sh
```

### update-dependencies.sh
Updates all Helm chart dependencies. Run this when external chart versions need updating.
```bash
cd /path/to/infrastructure
./scripts/update-dependencies.sh
```

## What the scripts do

1. **Build Helm Dependencies**: Downloads external Helm charts (NiFi, GitLab, InfluxDB, LibreChat)
2. **Deploy Root Application**: Uses Helm to deploy/upgrade the ArgoCD root application
3. **Verify Deployment**: Checks the status of deployed applications

## Using Make directly

You can also use the Makefile directly:

```bash
# Build all dependencies
make deps-all

# Deploy to specific environment
make deploy-dev
make deploy-staging
make deploy-prod

# Verify deployment status
make verify-dev
make verify-staging
make verify-prod

# Clean dependencies (remove downloaded charts)
make clean-deps
```

## CI/CD Integration

For CI/CD pipelines, you can use the make commands directly:

```yaml
# Example GitHub Actions
- name: Build dependencies
  run: make deps-all
  
- name: Deploy to dev
  run: make deploy-dev
```