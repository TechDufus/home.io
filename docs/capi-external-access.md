# External Access for CAPI Clusters

This guide explains how to set up secure external access to services running on CAPI-managed Kubernetes clusters using Cloudflare Tunnel with automatic SSL certificates.

## Overview

Each CAPI-managed cluster can have its own Cloudflare Tunnel for external access, providing:

- **Automatic SSL certificates** via Cloudflare
- **No exposed ports** - Your home IP stays private
- **Per-cluster isolation** - Each cluster has its own tunnel
- **Dual-domain strategy**: 
  - Internal: `service-cluster.home.io`
  - External: `service-cluster.lab.techdufus.com`

## Architecture

```
Internet → Cloudflare → Tunnel → Cluster Ingress → Service
```

### Domain Pattern
- **ArgoCD**: `argocd-dev-cluster.lab.techdufus.com`
- **Grafana**: `grafana-prod-cluster.lab.techdufus.com`
- **Custom Apps**: `app-cluster-name.lab.techdufus.com`

## Quick Setup

### 1. Setup External Access for a Cluster

```bash
# For ArgoCD only
./kubernetes/capi/scripts/setup-external-access.sh --name dev-cluster

# For multiple services
./kubernetes/capi/scripts/setup-external-access.sh \
  --name prod-cluster \
  --services "argocd,grafana,app"
```

### 2. Create Cloudflare Tunnel

When running the script, you'll need to:

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** → **Tunnels**
3. Create a tunnel named `{cluster-name}-tunnel`
4. Copy the tunnel token

### 3. Configure DNS Records

The tunnel will automatically create CNAME records, but verify in Cloudflare DNS:

```
argocd-dev-cluster.lab.techdufus.com → {tunnel-id}.cfargotunnel.com
grafana-prod-cluster.lab.techdufus.com → {tunnel-id}.cfargotunnel.com
```

## Manual Configuration

### Step 1: Create Tunnel Resources

```bash
# Set cluster context
export KUBECONFIG=~/.kube/config-dev-cluster

# Apply tunnel configuration
kubectl apply -f kubernetes/capi/addons/cloudflare-tunnel/
```

### Step 2: Configure Tunnel Token

```bash
# Base64 encode your tunnel token
echo -n "your-tunnel-token" | base64

# Update the secret
kubectl patch secret cloudflare-tunnel-token -n cloudflare-tunnel \
  --type='json' -p='[{"op": "replace", "path": "/data/token", "value":"<base64-token>"}]'
```

### Step 3: Update Tunnel Configuration

Edit the ConfigMap to add your services:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflare-tunnel-config
  namespace: cloudflare-tunnel
data:
  config.yaml: |
    tunnel: dev-cluster-tunnel
    ingress:
      - hostname: argocd-dev-cluster.lab.techdufus.com
        service: http://argocd-server.argocd.svc.cluster.local:80
        originRequest:
          httpHostHeader: argocd-dev-cluster.home.io
      - service: http_status:404
```

## Service Configuration

### ArgoCD with External Access

ArgoCD is automatically configured with dual-domain ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-dual-domain
  namespace: argocd
spec:
  rules:
  - host: argocd-dev-cluster.home.io     # Internal
  - host: argocd-dev-cluster.lab.techdufus.com  # External
```

### Custom Application Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-dual-domain
  namespace: default
spec:
  rules:
  - host: my-app-dev-cluster.home.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
  - host: my-app-dev-cluster.lab.techdufus.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app
            port:
              number: 80
```

Then add to tunnel configuration:

```yaml
- hostname: my-app-dev-cluster.lab.techdufus.com
  service: http://my-app.default.svc.cluster.local:80
  originRequest:
    httpHostHeader: my-app-dev-cluster.home.io
```

## Multi-Cluster Setup

### Cluster-Specific Tunnels

Each cluster gets its own tunnel for isolation:

| Cluster | Tunnel Name | ArgoCD External URL |
|---------|-------------|-------------------|
| dev-cluster | dev-cluster-tunnel | argocd-dev-cluster.lab.techdufus.com |
| prod-cluster | prod-cluster-tunnel | argocd-prod-cluster.lab.techdufus.com |

### Benefits of Per-Cluster Tunnels

1. **Isolation**: Issues with one tunnel don't affect others
2. **Security**: Granular access control per cluster
3. **Scaling**: Independent tunnel performance
4. **Management**: Clear separation of concerns

## Security Configuration

### Cloudflare Settings

1. **SSL/TLS Mode**: Set to "Full (strict)"
2. **Always Use HTTPS**: Enable
3. **HSTS**: Enable for additional security

### Access Policies (Optional)

For sensitive services, add Cloudflare Access policies:

1. Go to **Access** → **Applications**
2. Create application for your service
3. Set authentication requirements
4. Configure session duration

### Network Policies

Restrict tunnel pod access within the cluster:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cloudflare-tunnel-policy
  namespace: cloudflare-tunnel
spec:
  podSelector:
    matchLabels:
      app: cloudflare-tunnel
  policyTypes:
  - Egress
  egress:
  - to: []  # Allow all egress (needed for Cloudflare connectivity)
```

## Monitoring and Troubleshooting

### Check Tunnel Status

```bash
# View tunnel pods
kubectl get pods -n cloudflare-tunnel

# Check tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel

# View tunnel metrics
kubectl port-forward -n cloudflare-tunnel svc/cloudflare-tunnel-metrics 9090:9090
```

### Common Issues

#### 1. Tunnel Not Connecting

```bash
# Check tunnel token
kubectl get secret cloudflare-tunnel-token -n cloudflare-tunnel -o yaml

# Verify configuration
kubectl get configmap cloudflare-tunnel-config -n cloudflare-tunnel -o yaml

# Check pod status
kubectl describe pod -n cloudflare-tunnel -l app=cloudflare-tunnel
```

#### 2. Service Not Accessible

```bash
# Check ingress configuration
kubectl get ingress -A

# Test internal service connectivity
kubectl run test-pod --image=curlimages/curl --rm -it -- sh
# curl http://argocd-server.argocd.svc.cluster.local:80
```

#### 3. DNS Issues

```bash
# Verify DNS records in Cloudflare
dig argocd-dev-cluster.lab.techdufus.com

# Check tunnel endpoint
nslookup {tunnel-id}.cfargotunnel.com
```

### Debug Commands

```bash
# Comprehensive tunnel status
kubectl get all -n cloudflare-tunnel

# Service discovery test
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash
# nslookup argocd-server.argocd.svc.cluster.local

# Tunnel configuration validation
kubectl exec -n cloudflare-tunnel deployment/cloudflare-tunnel -- \
  cloudflared tunnel --config /etc/cloudflared/config/config.yaml validate
```

## Automation Integration

### ArgoCD Application for Tunnel

Create an ArgoCD application to manage tunnel configuration:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cloudflare-tunnel
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://github.com/techdufus/home.io
    path: kubernetes/capi/addons/cloudflare-tunnel
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: cloudflare-tunnel
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### CI/CD Integration

```bash
# Update tunnel configuration via script
./kubernetes/capi/scripts/setup-external-access.sh \
  --name $CLUSTER_NAME \
  --token $TUNNEL_TOKEN \
  --services $SERVICES_LIST
```

## Cost and Limitations

### Cloudflare Tunnel Limits (Free Tier)

- **Bandwidth**: Unlimited
- **Requests**: 1000 requests/minute per tunnel
- **Tunnels**: Unlimited tunnels
- **Domains**: Unlimited subdomains

### Scaling Considerations

- Each cluster can have its own tunnel
- Multiple replicas provide high availability
- Monitor tunnel metrics for performance

## Integration with CAPI Operations

### Cluster Creation with External Access

```bash
# Create cluster
./kubernetes/capi/scripts/create-cluster.sh --name new-cluster --env dev

# Install ArgoCD with external access
./kubernetes/capi/scripts/install-argocd.sh --name new-cluster

# Setup external access
./kubernetes/capi/scripts/setup-external-access.sh --name new-cluster
```

### Cluster Deletion Cleanup

```bash
# Remove tunnel configuration from Cloudflare dashboard
# Delete cluster (tunnel resources are automatically cleaned up)
./kubernetes/capi/scripts/delete-cluster.sh --name old-cluster
```

This external access setup provides enterprise-grade security with automatic SSL certificates while maintaining the flexibility to expose different services per cluster as needed.