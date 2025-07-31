# Kubernetes Applications

This directory contains all Kubernetes applications managed by ArgoCD using the GitOps pattern.

## Directory Structure

```
apps/
├── argocd/                  # ArgoCD application definitions
│   ├── base/               # Base configurations
│   │   ├── apps/          # Application definitions
│   │   └── values/        # Base Helm values
│   └── overlays/          # Environment-specific overrides
│       └── dev/
│           └── values/    # Dev-specific Helm values
├── core/                   # Core infrastructure applications
│   └── cloudflared/       # Cloudflare Tunnel for ingress
└── services/              # User-facing services
    └── (future apps)      # n8n, pihole, etc. when using local manifests
```

## Application Management

### Application Types

1. **Helm-based Applications**: Apps deployed using Helm charts
   - Values defined in `argocd/base/values/`
   - Environment overrides in `argocd/overlays/dev/values/`
   - Examples: cert-manager, external-secrets, n8n

2. **Manifest-based Applications**: Apps using raw Kubernetes manifests
   - Manifests stored in `core/` or `services/`
   - Managed with Kustomize
   - Example: cloudflared

### Adding a New Application

#### For Helm-based Apps:

1. Create app definition in `argocd/base/apps/myapp.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  sources:
    - chart: myapp
      repoURL: https://charts.example.com
      targetRevision: 1.0.0
      helm:
        valueFiles:
          - $values/argocd/overlays/dev/values/myapp.yaml
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      ref: values
```

2. Create base values in `argocd/base/values/myapp.yaml`
3. Create env-specific values in `argocd/overlays/dev/values/myapp.yaml`
4. Add to kustomization files

#### For Manifest-based Apps:

1. Create directory structure in `core/` or `services/`
2. Add Kubernetes manifests
3. Create `kustomization.yaml`
4. Create app definition pointing to the directory

## Deployment Flow

1. **Manual Bootstrap**:
   ```bash
   cd terraform/proxmox/environments/dev/argocd
   terraform init
   terraform apply
   ```

2. **GitOps Sync**:
   - ArgoCD watches this repository
   - Changes to manifests trigger automatic sync
   - Applications deploy in order: core → services

## Environment Management

- **Dev Environment**: `overlays/dev/`
  - Development configurations
  - Debug logging enabled
  - Relaxed resource limits

- **Future Environments**: `overlays/staging/`, `overlays/prod/`
  - Production configurations
  - Stricter security policies
  - Higher resource allocations

## Best Practices

1. **Never commit secrets** - Use External Secrets Operator
2. **Use semantic versioning** for Helm chart versions
3. **Test in dev** before promoting to production
4. **Keep base values minimal** - Environment-specific in overlays
5. **Document any manual steps** in app-specific READMEs

## Common Tasks

### View Application Status
```bash
kubectl get applications -n argocd
```

### Sync an Application
```bash
kubectl patch application myapp -n argocd --type merge -p '{"operation": {"sync": {}}}'
```

### Debug Sync Issues
```bash
kubectl logs -n argocd deployment/argocd-application-controller
```

## ArgoCD Access

After deployment:
```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Access UI
open https://localhost:8080
```

Once Cloudflare Tunnel is configured, access via:
- https://argocd.home.techdufus.com