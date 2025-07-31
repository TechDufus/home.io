# Kubernetes GitOps Workflow

This document describes the modern Kubernetes-first approach for deploying applications in the homelab using Terraform, Kubernetes, and ArgoCD.

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Terraform     │────▶│  Talos/K8s       │────▶│    ArgoCD       │
│   (Proxmox)     │     │   Cluster        │     │   (GitOps)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                       │                         │
         │                       │                         │
    Infrastructure          Platform                 Applications
    - VMs                   - Nodes              - Deployments
    - Networking           - Storage             - Services
    - Templates            - Networking          - Ingress
```

## Workflow

1. **Infrastructure**: Terraform provisions Talos Kubernetes nodes on Proxmox
2. **Platform**: Talos bootstraps a production-ready Kubernetes cluster
3. **GitOps**: ArgoCD manages all applications declaratively from Git

## Benefits

- **Declarative Everything**: Infrastructure and apps defined as code
- **Self-Healing**: ArgoCD ensures cluster state matches Git
- **Scalability**: Easy to add nodes or applications
- **Rollback**: Git history provides instant rollback capability
- **Multi-Cluster**: Manage multiple clusters from single ArgoCD

## Directory Structure

```
kubernetes/
├── bootstrap/              # ArgoCD installation and initial setup
│   ├── argocd/
│   │   ├── install.sh     # ArgoCD installation script
│   │   └── values.yaml    # ArgoCD Helm values
│   └── prerequisites/      # Cluster prerequisites
│       ├── namespaces.yaml
│       └── secrets/
├── apps/                   # Application definitions
│   ├── argocd-apps/       # App of Apps pattern
│   │   ├── root.yaml      # Root application
│   │   └── apps/          # Individual app definitions
│   ├── core/              # Core cluster services
│   │   ├── cert-manager/
│   │   ├── ingress-nginx/
│   │   └── metallb/
│   └── services/          # User-facing services
│       ├── n8n/
│       ├── pihole/
│       └── portainer/
└── environments/          # Environment-specific configs
    ├── dev/
    └── prod/
```

## Quick Start

### 1. Deploy Kubernetes Cluster with Terraform

```bash
cd terraform/proxmox/environments/dev
terraform apply
```

### 2. Bootstrap Cluster

```bash
cd ~/home.io

# Setup secrets from 1Password
./kubernetes/bootstrap/setup-secrets.sh dev

# Install ArgoCD
./kubernetes/bootstrap/argocd.sh dev
```

### 3. Access ArgoCD UI

```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login localhost:8080
```

### 4. Watch Applications Sync

```bash
# The bootstrap script already created the root app
# Just watch it sync all other apps
kubectl get apps -n argocd -w
```

## Application Management

### Adding a New Application

1. Create application manifests in `kubernetes/apps/services/[app-name]/`
2. Create ArgoCD Application definition in `kubernetes/apps/argocd-apps/apps/`
3. Commit and push to Git
4. ArgoCD automatically syncs and deploys

### Example: Deploying n8n

```yaml
# kubernetes/apps/argocd-apps/apps/n8n.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n8n
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/TechDufus/home.io
    targetRevision: main
    path: kubernetes/apps/services/n8n
  destination:
    server: https://kubernetes.default.svc
    namespace: n8n
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Best Practices

### 1. Environment Separation
- Use Kustomize overlays for dev/prod differences
- Separate ArgoCD projects for environments
- Use Git branches for environment promotion

### 2. Secret Management
- Use Sealed Secrets or External Secrets Operator
- Never commit plain secrets to Git
- Integrate with 1Password where possible

### 3. Resource Management
- Set resource requests/limits on all pods
- Use PodDisruptionBudgets for critical services
- Implement HorizontalPodAutoscalers where appropriate

### 4. Monitoring and Observability
- Deploy Prometheus/Grafana via ArgoCD
- Use ServiceMonitors for application metrics
- Implement proper logging with Loki

## Common Tasks

### Sync an Application
```bash
argocd app sync [app-name]
```

### Check Application Status
```bash
argocd app get [app-name]
```

### Rollback an Application
```bash
argocd app rollback [app-name] [revision]
```

### Delete an Application
```bash
argocd app delete [app-name]
```

## Troubleshooting

### Application Won't Sync
1. Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-server`
2. Verify Git credentials
3. Check RBAC permissions
4. Validate manifests locally

### Out of Sync Issues
1. Check for manual changes: `kubectl diff -f [manifest]`
2. Force sync: `argocd app sync [app-name] --force`
3. Check sync policies

### Performance Issues
1. Enable resource tracking
2. Limit application refresh rate
3. Use ApplicationSets for similar apps

## Migration from Ansible

To migrate existing Ansible-deployed services:

1. Extract configuration into Kubernetes manifests
2. Create PersistentVolumeClaims for data
3. Use init containers for initial setup
4. Implement proper health checks
5. Test in dev environment first

## Next Steps

- [ ] Create bootstrap script for ArgoCD
- [ ] Set up App of Apps pattern
- [ ] Migrate first service (n8n) to Kubernetes
- [ ] Implement secret management
- [ ] Add monitoring stack
- [ ] Document backup procedures