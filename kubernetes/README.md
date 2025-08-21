# Kubernetes GitOps Structure

This directory contains all Kubernetes resources managed via GitOps with ArgoCD.

## Directory Structure

```
kubernetes/
├── argocd/                 # All ArgoCD-related resources
│   ├── base/               # Base configuration
│   │   ├── apps/           # ArgoCD Application definitions
│   │   ├── charts/         # Local Helm charts (future)
│   │   ├── manifests/      # Raw Kubernetes manifests
│   │   │   ├── cloudflared/      # Cloudflare tunnel manifests
│   │   │   ├── cloudnative-pg/   # PostgreSQL operator examples
│   │   │   └── monitoring/       # Monitoring stack docs
│   │   └── kustomization.yaml
│   └── overlays/           # Environment-specific configurations
│       └── dev/            # Dev environment
│           ├── kustomization.yaml
│           ├── patches/    # Environment-specific patches
│           │   └── cloudflared/  # Patches for cloudflared
│           └── values/     # Helm values (external & local)
└── bootstrap/              # Bootstrap scripts
    ├── argocd.sh           # Install ArgoCD and create app-of-apps
    └── setup-secrets.sh    # Create secrets from 1Password
```

## Deployment Flow

1. **Bootstrap ArgoCD**: The `bootstrap/argocd.sh` script installs ArgoCD
2. **App-of-Apps**: The script creates the app-of-apps which manages all other applications
3. **Automatic Sync**: All applications are automatically deployed and kept in sync

## Adding New Applications

### 1. For Helm Charts

Create ArgoCD Application in `kubernetes/argocd/base/apps/my-app.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  sources:
    - chart: my-chart
      repoURL: https://charts.example.com
      targetRevision: "1.0.0"
      helm:
        valueFiles:
          - $values/argocd/overlays/ENVIRONMENT_PLACEHOLDER/values/my-app.yaml
    - repoURL: https://github.com/TechDufus/home.io
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: my-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 2. For Raw Manifests

1. Add manifests to `kubernetes/argocd/base/manifests/my-app/`
2. Create ArgoCD Application in `kubernetes/argocd/base/apps/my-app.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/TechDufus/home.io
    targetRevision: main
    path: kubernetes/argocd/overlays/dev  # Point to overlay for patched manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: my-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
3. Update `kubernetes/argocd/overlays/dev/kustomization.yaml` to include the manifests

### 3. Update ArgoCD Configuration

1. Add to `kubernetes/argocd/base/kustomization.yaml`:
   ```yaml
   resources:
     - apps/my-app.yaml
   ```

2. Add values to `kubernetes/argocd/overlays/dev/values/my-app.yaml`

3. Update `kubernetes/argocd/overlays/dev/kustomization.yaml` to patch the values path

## Quick Start

```bash
# 1. Deploy infrastructure with Terraform
cd terraform/proxmox/environments/dev
terraform apply

# 2. Setup secrets
cd ~/home.io
./kubernetes/bootstrap/setup-secrets.sh dev

# 3. Bootstrap ArgoCD and deploy all apps
./kubernetes/bootstrap/argocd.sh dev

# 4. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Username: admin
# Password: (shown in script output)
```

## Deployment Patterns

The structure supports three deployment patterns:

### 1. External Helm Charts
Used for community charts (monitoring, cloudnative-pg). Configure via:
- ArgoCD app with multi-source in `base/apps/`
- Values in `overlays/dev/values/`

### 2. Local Helm Charts (Future)
For complex internal applications that need templating:
- Chart definition in `base/charts/`
- ArgoCD app with local chart path
- Values in `overlays/dev/values/`

### 3. Raw Manifests
For simple applications or when Helm isn't needed:
- Manifests in `base/manifests/`
- ArgoCD app points to overlay path
- Patches in `overlays/dev/patches/`

## Environment Management

Currently using a single environment (dev). To add more environments:

1. Create new overlay directory: `kubernetes/argocd/overlays/prod/`
2. Copy and modify values from dev overlay
3. Update bootstrap script to deploy correct environment
4. All environment-specific configuration stays in the overlay

## Secret Management

Secrets are managed via 1Password and injected using `setup-secrets.sh`. Never commit secrets to Git!