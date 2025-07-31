# Kubernetes GitOps Structure

This directory contains all Kubernetes resources managed via GitOps with ArgoCD.

## Directory Structure

```
kubernetes/
├── apps/                    # Application manifests and resources
│   ├── cloudflared/        # Cloudflare tunnel manifests
│   ├── cloudnative-pg/     # PostgreSQL operator examples
│   ├── monitoring/         # Monitoring stack docs
│   └── n8n/                # n8n manifests (future)
├── argocd/                 # ArgoCD app definitions and values
│   ├── base/               # Base applications with placeholders
│   │   ├── apps/           # Application definitions
│   │   └── values/         # Default values (if any)
│   └── overlays/           # Environment-specific configurations
│       └── dev/            # Dev environment
│           └── values/     # All values for dev environment
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

Create ArgoCD Application in `kubernetes/argocd-apps/my-app.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    chart: my-chart
    repoURL: https://charts.example.com
    targetRevision: "1.0.0"
    helm:
      valueFiles:
        - https://raw.githubusercontent.com/TechDufus/home.io/main/kubernetes/apps/my-app/values.yaml
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

Create ArgoCD Application in `kubernetes/argocd-apps/my-app.yaml`:
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
    path: kubernetes/apps/my-app
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

### 3. Update Kustomization

Add your new app to `kubernetes/argocd-apps/kustomization.yaml`:
```yaml
resources:
  - existing-apps.yaml
  - my-app.yaml  # Add this line
```

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

## Environment Management

Currently using a single environment (dev). To add more environments:

1. Create environment-specific values in `kubernetes/apps/[app-name]/values-[env].yaml`
2. Update ArgoCD applications to reference the correct values file
3. Consider using Kustomize overlays for more complex scenarios

## Secret Management

Secrets are managed via 1Password and injected using `setup-secrets.sh`. Never commit secrets to Git!