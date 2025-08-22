# Kubernetes GitOps Structure

This directory contains all Kubernetes resources managed via GitOps with ArgoCD.

## Directory Structure

```
kubernetes/
├── argocd/                 # All ArgoCD-related resources
│   ├── base/               # Base configuration
│   │   ├── apps/           # ArgoCD Application definitions
│   │   │   ├── gateway-api-crds.yaml  # Gateway API CRDs (deploy first)
│   │   │   └── traefik.yaml           # Traefik gateway controller
│   │   └── kustomization.yaml
│   └── overlays/           # Environment-specific configurations
│       └── dev/            # Dev environment
│           ├── gateway/    # Gateway configurations
│           │   └── argocd-httproute.yaml  # Expose ArgoCD UI
│           ├── values/     # Helm values
│           │   └── traefik.yaml           # Traefik configuration
│           └── kustomization.yaml
└── bootstrap/              # Bootstrap scripts
    ├── argocd.sh           # Install ArgoCD and create app-of-apps
    └── setup-secrets.sh    # Create secrets from 1Password
```

## Quick Start

```bash
# 1. Deploy infrastructure with Terraform (if not already done)
cd terraform/proxmox/environments/dev
terraform apply

# 2. Bootstrap ArgoCD and deploy gateway
cd ~/home.io
./kubernetes/bootstrap/argocd.sh dev

# 3. Wait for Gateway API CRDs to be installed
kubectl wait --for condition=established --timeout=60s crd/gateways.gateway.networking.k8s.io

# 4. Access ArgoCD UI (after gateway is ready)
# Add to /etc/hosts or use DNS:
# <TRAEFIK_LOADBALANCER_IP> argocd.home.io

# Get the LoadBalancer IP:
kubectl get svc traefik -n traefik

# Get ArgoCD admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Architecture

### Core Components

1. **Gateway API CRDs** - Standard Kubernetes Gateway API v1.2.1
   - Provides vendor-neutral API for traffic management
   - Required by any Gateway API implementation

2. **Traefik Gateway** - Lightweight gateway controller
   - Implements Gateway API specification
   - Provides HTTP/HTTPS routing
   - Simple configuration via Helm values

3. **ArgoCD** - GitOps continuous deployment
   - Manages all applications declaratively
   - Auto-syncs from this Git repository

## Adding Applications

### Step 1: Create ArgoCD Application

Create a new application definition in `kubernetes/argocd/base/apps/my-app.yaml`:

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
    path: kubernetes/argocd/base/manifests/my-app
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

### Step 2: Add to Kustomization

Update `kubernetes/argocd/base/kustomization.yaml`:

```yaml
resources:
  - apps/gateway-api-crds.yaml
  - apps/traefik.yaml
  - apps/my-app.yaml  # Add your app here
```

### Step 3: Expose via Gateway (Optional)

To expose your app externally, create an HTTPRoute in `kubernetes/argocd/overlays/dev/gateway/`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
  namespace: my-namespace
spec:
  parentRefs:
    - name: homelab-gateway
      namespace: traefik
  hostnames:
    - "my-app.home.io"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: my-app-service
          port: 80
```

## Gateway Configuration

### Current Setup

- **Gateway Controller**: Traefik v3.x with Gateway API support
- **Gateway Class**: `traefik` (default)
- **Gateway**: `homelab-gateway` in `traefik` namespace
- **Exposed Services**:
  - ArgoCD UI: `argocd.home.io`

### Adding TLS/HTTPS

1. **Option 1: Self-signed (current)**
   - Basic TLS secret included for testing
   - Browser will show certificate warning

2. **Option 2: cert-manager (recommended)**
   - Install cert-manager application
   - Configure Let's Encrypt issuer
   - Update Gateway to reference certificates

3. **Option 3: External certificates**
   - Store in 1Password
   - Use External Secrets Operator
   - Reference in Gateway configuration

## Troubleshooting

### Check Gateway Status

```bash
# Gateway API resources
kubectl get gatewayclass
kubectl get gateway -A
kubectl get httproute -A

# Traefik status
kubectl get pods -n traefik
kubectl logs -n traefik deployment/traefik

# Service status
kubectl get svc -n traefik
```

### Common Issues

1. **Gateway not accepting routes**
   - Check GatewayClass exists and is accepted
   - Verify Gateway listeners are programmed
   - Check namespace selectors in Gateway

2. **Routes not working**
   - Verify HTTPRoute parentRef matches Gateway
   - Check backend service exists and has endpoints
   - Look at Traefik logs for errors

3. **Cannot access ArgoCD**
   - Ensure DNS/hosts file points to LoadBalancer IP
   - Check HTTPRoute is attached to Gateway
   - Verify ArgoCD server pod is running

## Next Steps

Once the gateway is working:

1. **Add DNS management**
   - External-DNS for automatic DNS updates
   - Or Pi-hole for local DNS

2. **Add TLS certificates**
   - cert-manager for automatic certificates
   - Let's Encrypt or self-signed CA

3. **Add monitoring**
   - Prometheus for metrics
   - Grafana for visualization

4. **Add your applications**
   - One at a time
   - Test each before adding the next

## Architecture Decisions

### Why Gateway API?
- Future-proof: Kubernetes standard
- Vendor-neutral: Not locked to one implementation
- Flexible: Easy to switch gateway controllers
- GitOps-friendly: Everything is declarative

### Why Traefik?
- Simple: No service mesh complexity
- Lightweight: Minimal resource usage
- Gateway API: Full support for v1.2.1
- Production-ready: Battle-tested gateway

### Why This Structure?
- Minimal: Start with just gateway + ArgoCD
- Extensible: Easy to add applications
- Standard: Uses Kubernetes best practices
- GitOps: Everything in Git, nothing manual