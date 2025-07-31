# Kubernetes Bootstrap Scripts

This directory contains bootstrap scripts for setting up the Kubernetes cluster and core components.

## Overview

The bootstrap process consists of two main scripts that should be run in order:

1. **setup-secrets.sh** - Pulls secrets from 1Password and creates Kubernetes secrets
2. **argocd.sh** - Installs ArgoCD and creates the bootstrap application

## Setup Secrets

The `setup-secrets.sh` script creates all necessary secrets from 1Password before deploying applications.

### Usage

```bash
# Setup secrets for dev environment (default)
./kubernetes/bootstrap/setup-secrets.sh

# Setup secrets for production
./kubernetes/bootstrap/setup-secrets.sh prod
```

### What it does

1. Connects to your 1Password vault
2. Creates Cloudflare Tunnel credentials
3. Creates application secrets (N8N, etc.)
4. Shows status of all created secrets

## ArgoCD Bootstrap

The `argocd.sh` script provides a simple way to install ArgoCD and configure it for GitOps.

### Prerequisites

1. A running Kubernetes cluster
2. Valid kubeconfig with cluster access
3. `kubectl` installed and configured

### Usage

```bash
# Bootstrap ArgoCD for dev environment (default)
./kubernetes/bootstrap/argocd.sh

# Bootstrap ArgoCD for production
./kubernetes/bootstrap/argocd.sh prod

# Show help
./kubernetes/bootstrap/argocd.sh --help
```

### What it does

1. **Installs ArgoCD**: Deploys all ArgoCD components
2. **Configures for homelab**: Sets insecure mode (we use Cloudflare Tunnel for TLS)
3. **Creates bootstrap app**: Sets up app-of-apps pattern
4. **Shows credentials**: Displays initial admin password

### Complete Workflow

```bash
# 1. Deploy Kubernetes cluster
cd terraform/proxmox/environments/dev
terraform apply

# 2. Setup secrets from 1Password
cd ~/home.io
./kubernetes/bootstrap/setup-secrets.sh dev

# 3. Bootstrap ArgoCD
./kubernetes/bootstrap/argocd.sh dev

# 4. Access ArgoCD (temporarily)
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Open http://localhost:8080

# 5. Watch applications sync
kubectl get apps -n argocd -w
```

### Post-Bootstrap

After bootstrapping, ArgoCD will automatically:

1. Deploy Cloudflare Tunnel
2. Deploy N8N
3. Deploy any other configured applications

Once Cloudflare Tunnel is running, you can access ArgoCD at:
- https://argocd.home.techdufus.com

### Customization

You can customize the bootstrap by setting environment variables:

```bash
# Use a different ArgoCD version
ARGOCD_VERSION=v2.10.0 ./kubernetes/bootstrap/argocd.sh

# Track a different Git branch
REPO_BRANCH=develop ./kubernetes/bootstrap/argocd.sh
```

### Troubleshooting

**ArgoCD not starting:**
```bash
kubectl get pods -n argocd
kubectl describe pod -n argocd <pod-name>
```

**Bootstrap app not syncing:**
```bash
kubectl get app bootstrap-dev -n argocd
kubectl describe app bootstrap-dev -n argocd
```

**View ArgoCD logs:**
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
```

### Uninstall

To remove ArgoCD (this will also remove all apps it manages):

```bash
# Delete the bootstrap app first
kubectl delete app bootstrap-dev -n argocd

# Delete ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.11.3/manifests/install.yaml

# Delete namespace
kubectl delete namespace argocd
```