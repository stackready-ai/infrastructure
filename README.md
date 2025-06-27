# ArgoCD App of Apps Deployment

This repository contains Helm charts structured using the ArgoCD App of Apps pattern for deploying:
- Apache NiFi
- GitLab
- Kubeflow
- InfluxDB
- LibreChat

## Prerequisites

1. Kubernetes cluster (1.25+)
2. ArgoCD installed in the cluster
3. Helm 3.x
4. kubectl configured to access your cluster

## Structure

```
argocd-apps/
├── root/                    # Root App of Apps chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── nifi.yaml
│       ├── gitlab.yaml
│       ├── kubeflow.yaml
│       └── influxdb.yaml
└── applications/           # Individual application charts
    ├── nifi/
    ├── gitlab/
    ├── kubeflow/
    ├── influxdb/
    └── librechat/
```

## Deployment Steps

### 1. Install ArgoCD (if not already installed)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Configure Git Repository

Update the `argocd-apps/root/values.yaml` file with your Git repository URL:

```yaml
spec:
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
```

### 3. Deploy the Root Application

```bash
# Option 1: Using kubectl
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: argocd-apps/root
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Option 2: Using ArgoCD CLI
argocd app create root-app \
  --repo https://github.com/your-org/your-repo \
  --path argocd-apps/root \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

### 4. Sync the Root Application

```bash
argocd app sync root-app
```

## Configuration

### Enabling/Disabling Applications

In `argocd-apps/root/values.yaml`, set `enabled: false` for any application you don't want to deploy:

```yaml
applications:
  nifi:
    enabled: false  # This will prevent NiFi from being deployed
```

### Customizing Applications

Each application has its own `values.yaml` file in its respective directory:

- **NiFi**: `argocd-apps/applications/nifi/values.yaml`
- **GitLab**: `argocd-apps/applications/gitlab/values.yaml`
- **Kubeflow**: `argocd-apps/applications/kubeflow/values.yaml`
- **InfluxDB**: `argocd-apps/applications/influxdb/values.yaml`
- **LibreChat**: `argocd-apps/applications/librechat/values.yaml`

### Important Configuration Items

#### Domain Names
Update all domain references in the values files:
- `nifi.example.com` → Your NiFi domain
- `gitlab.example.com` → Your GitLab domain
- `kubeflow.example.com` → Your Kubeflow domain
- `influxdb.example.com` → Your InfluxDB domain
- `librechat.example.com` → Your LibreChat domain

#### Storage Classes
Ensure the `storageClass` values match your cluster's available storage classes:
```bash
kubectl get storageclass
```

#### Ingress Controller
The charts assume NGINX ingress controller with cert-manager. Update if using different ingress.

## Security Considerations

1. **Change Default Passwords**: All default passwords in the values files should be changed:
   - NiFi: `auth.singleUser.password`
   - GitLab: `global.initialRootPassword`
   - Kubeflow: `dexAuth.staticPasswords`
   - InfluxDB: `adminUser.password`
   - LibreChat: `config.credsKey`, `config.jwtSecret`, `mongodb.auth.rootPassword`

2. **TLS Certificates**: The charts are configured to use cert-manager with Let's Encrypt. Ensure cert-manager is installed:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

3. **Network Policies**: Consider implementing network policies to restrict traffic between namespaces.

## Monitoring

To monitor the deployment status:

```bash
# Check all applications
argocd app list

# Check specific application
argocd app get <app-name>

# View application logs
argocd app logs <app-name>
```

## Troubleshooting

### Application Not Syncing
```bash
# Force sync
argocd app sync <app-name> --force

# Check application details
kubectl describe application <app-name> -n argocd
```

### Pod Issues
```bash
# Check pods in application namespace
kubectl get pods -n <namespace>

# View pod logs
kubectl logs -n <namespace> <pod-name>
```

### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n <namespace>

# Check PV status
kubectl get pv
```

## Uninstalling

To remove all applications:

```bash
# Delete the root application (this will cascade delete all child apps)
argocd app delete root-app --cascade

# Or using kubectl
kubectl delete application root-app -n argocd
```

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Apache NiFi](https://nifi.apache.org/)
- [GitLab](https://about.gitlab.com/)
- [Kubeflow](https://www.kubeflow.org/)
- [InfluxDB](https://www.influxdata.com/)
- [LibreChat](https://www.librechat.ai/)