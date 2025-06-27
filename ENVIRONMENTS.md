# Environment Management Guide

This infrastructure now supports multiple environments (dev, staging, prod) using Kustomize overlays.

## Directory Structure

```
applications/
├── base/                    # Base configurations for all applications
│   ├── nifi/
│   ├── gitlab/
│   ├── kubeflow/
│   ├── influxdb/
│   ├── librechat/
│   └── loadbalancer/
└── overlays/               # Environment-specific overrides
    ├── dev/
    ├── staging/
    └── prod/

root/                       # ArgoCD root applications
├── dev/                    # Development environment root app
├── staging/                # Staging environment root app
└── prod/                   # Production environment root app
```

## Deployment

### Deploy Specific Environments

```bash
# Deploy development environment
make deploy-dev

# Deploy staging environment
make deploy-staging

# Deploy production environment (requires confirmation)
make deploy-prod
```

### Check Environment Status

```bash
# Check development environment
make status-dev

# Check staging environment
make status-staging

# Check production environment
make status-prod
```

### Sync Applications

```bash
# Sync all dev applications
make sync-dev

# Sync all staging applications
make sync-staging

# Sync all production applications (requires confirmation)
make sync-prod
```

## Environment Differences

### Development
- Minimal resource allocations
- Single replicas
- Smaller storage volumes
- Internal load balancers
- Dev-specific domains (*.dev.example.com)

### Staging
- Moderate resource allocations
- Multiple replicas for testing HA
- Medium storage volumes
- Standard load balancers
- Staging domains (*.staging.example.com)

### Production
- Full resource allocations
- Multiple replicas for HA
- Large storage volumes
- SSL-enabled load balancers
- Production domains (*.example.com)

## Customizing Environments

To modify environment-specific settings:

1. Edit the values file in `applications/overlays/{env}/{app}-values.yaml`
2. Commit and push changes
3. Run `make sync-{env}` to apply changes

## Adding New Applications

1. Create base configuration in `applications/base/{new-app}/`
2. Create environment overrides in each `applications/overlays/{env}/`
3. Update `applications/base/kustomization.yaml`
4. Update each `applications/overlays/{env}/kustomization.yaml`
5. Add application to each `root/{env}/values.yaml`
6. Deploy using `make deploy-{env}`

## Best Practices

1. **Always test in dev first** before promoting to staging
2. **Use staging** to validate production-like configurations
3. **Require approval** for production deployments
4. **Monitor resource usage** and adjust limits accordingly
5. **Keep secrets separate** per environment
6. **Use different clusters** for true isolation (optional)