# CAPI Kubernetes Clusters with Gateway API

This directory contains Cluster API (CAPI) configurations for creating and managing Kubernetes clusters on Proxmox, with modern Gateway API for traffic routing.

## Architecture

Our CAPI setup provides:

- **Proxmox Infrastructure**: VM provisioning via Proxmox provider
- **Gateway API**: Modern traffic routing replacing traditional Ingress
- **Dual-Domain Strategy**: Internal (*.home.io) and external (*.lab.techdufus.com) access
- **Cloudflare Tunnel**: Secure external access without exposing home IP
- **GitOps Ready**: ArgoCD integration for continuous deployment

## Directory Structure

```
kubernetes/capi/
├── README.md                          # This documentation
├── addons/                            # Cluster addons and configurations
│   ├── gateway-api/                   # Gateway API resources
│   │   ├── gatewayclass.yaml         # Gateway controller definitions
│   │   ├── gateways.yaml             # Internal/external gateways
│   │   └── httproutes/               # Service routing configurations
│   │       ├── argocd.yaml           # ArgoCD HTTPRoutes
│   │       ├── grafana.yaml          # Grafana HTTPRoutes
│   │       └── app-template.yaml     # Template for custom apps
│   └── cloudflare-tunnel-gateway/    # Cloudflare tunnel for Gateway API
│       ├── configmap.yaml            # Tunnel configuration
│       └── deployment.yaml           # Tunnel deployment
├── clusters/                          # Cluster definitions
│   ├── templates/                     # Cluster templates
│   │   └── cluster-template.yaml     # Base cluster template
│   └── environments/                  # Environment-specific configs
│       ├── dev/                       # Development environment
│       └── prod/                      # Production environment
└── scripts/                           # Management scripts
    ├── create-cluster.sh              # Create new clusters
    ├── delete-cluster.sh              # Delete clusters
    ├── install-argocd.sh              # Install ArgoCD with HTTPRoutes
    ├── install-gateway-api.sh         # Install Gateway API components
    └── setup-external-access.sh       # Configure external access
```

## Gateway API Overview

### Why Gateway API?

Gateway API is the successor to Kubernetes Ingress, providing:

- **Expressive**: Supports advanced routing features (header-based routing, traffic splitting)
- **Extensible**: Provider-specific features without vendor lock-in
- **Role-Oriented**: Separate resources for infrastructure and application teams
- **Type Safety**: Strongly typed API with better validation

### Key Resources

1. **GatewayClass**: Defines the controller (nginx, istio, cilium)
2. **Gateway**: Configures listeners and TLS
3. **HTTPRoute**: Defines routing rules and backends

### Dual-Gateway Architecture

We deploy two separate gateways:

#### Internal Gateway
- **Hostname Pattern**: `*.${CLUSTER_NAME}.home.io`
- **Purpose**: Internal network access
- **TLS**: Self-signed certificates
- **MetalLB Pool**: `internal-pool` (10.0.20.200-10.0.20.209)

#### External Gateway  
- **Hostname Pattern**: `*.${CLUSTER_NAME}.lab.techdufus.com`
- **Purpose**: External access via Cloudflare Tunnel
- **TLS**: Cloudflare-managed certificates
- **MetalLB Pool**: `external-pool` (10.0.20.210-10.0.20.219)

## Quick Start

### 1. Create a New Cluster

```bash
# Create development cluster with Gateway API
./scripts/create-cluster.sh --name dev --env dev --install-addons

# Create production cluster
./scripts/create-cluster.sh --name prod --env prod --install-addons
```

### 2. Install ArgoCD with HTTPRoutes

```bash
# Install ArgoCD using Gateway API
./scripts/install-argocd.sh --name dev
```

### 3. Setup External Access

```bash
# Configure Cloudflare Tunnel and HTTPRoutes
./scripts/setup-external-access.sh --name dev --services "argocd,grafana"
```

### 4. Access Your Services

**Internal Access (VPN/Local Network):**
- ArgoCD: `https://argocd.dev.home.io`
- Grafana: `https://grafana.dev.home.io`

**External Access (Internet):**
- ArgoCD: `https://argocd.dev.lab.techdufus.com`
- Grafana: `https://grafana.dev.lab.techdufus.com`

**URL Pattern Examples:**
- Dev cluster: `service.dev.domain.com`
- Prod cluster: `service.prod.domain.com`

## Gateway API Usage

### Creating HTTPRoutes for New Services

Use the provided template for new applications:

```bash
# Copy template
cp addons/gateway-api/httproutes/app-template.yaml addons/gateway-api/httproutes/myapp.yaml

# Edit template variables
sed -i 's/${APP_NAME}/myapp/g' addons/gateway-api/httproutes/myapp.yaml
sed -i 's/${NAMESPACE}/default/g' addons/gateway-api/httproutes/myapp.yaml
sed -i 's/${APP_PORT}/8080/g' addons/gateway-api/httproutes/myapp.yaml
sed -i 's/${CLUSTER_NAME}/dev/g' addons/gateway-api/httproutes/myapp.yaml

# Apply to cluster (this creates: myapp.dev.home.io and myapp.dev.lab.techdufus.com)
kubectl apply -f addons/gateway-api/httproutes/myapp.yaml
```

### Advanced Routing Examples

#### Traffic Splitting (Canary Deployments)
```yaml
backendRefs:
- name: myapp-stable
  port: 8080
  weight: 90
- name: myapp-canary  
  port: 8080
  weight: 10
```

#### Header-Based Routing
```yaml
matches:
- headers:
  - name: X-User-Type
    value: beta
  path:
    type: PathPrefix
    value: /
```

#### Path Rewriting
```yaml
filters:
- type: URLRewrite
  urlRewrite:
    path:
      type: ReplacePrefixMatch
      replacePrefixMatch: /v2/
```

## Monitoring and Troubleshooting

### Check Gateway Status

```bash
# List all gateways
kubectl get gateways -A

# Check gateway details
kubectl describe gateway external-gateway -n nginx-gateway

# Check HTTPRoutes
kubectl get httproutes -A

# Verify route status
kubectl describe httproute argocd-external -n argocd
```

### Common Issues

#### HTTPRoute Not Accepted
```bash
# Check gateway controller logs
kubectl logs -n nginx-gateway -l app.kubernetes.io/name=nginx-gateway

# Verify parent reference
kubectl get gateway external-gateway -n nginx-gateway
```

#### Service Not Reachable
```bash
# Check service endpoints
kubectl get endpoints argocd-server -n argocd

# Verify MetalLB assignment
kubectl get services -A -o wide | grep LoadBalancer
```

#### Tunnel Connection Issues
```bash
# Check tunnel logs
kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel

# Verify tunnel configuration
kubectl get configmap cloudflare-tunnel-config -n cloudflare-tunnel -o yaml
```

## Migration from Ingress

When migrating from traditional Ingress:

1. **Keep Both**: Gateway API and Ingress can coexist
2. **Use Different Pools**: Separate MetalLB address pools
3. **Gradual Migration**: Move services one by one to HTTPRoutes
4. **Test Thoroughly**: Verify both internal and external access

### Migration Checklist

- [ ] Gateway API installed and running
- [ ] HTTPRoutes created for service  
- [ ] Internal access working (*.home.io)
- [ ] External access working (*.lab.techdufus.com)
- [ ] Monitoring/logging configured
- [ ] Remove old Ingress resources

## Security Considerations

### Network Policies
Gateway API pods include NetworkPolicy for:
- DNS resolution
- HTTPS to Cloudflare
- HTTP to gateway services
- Metrics collection

### TLS Configuration
- **Internal**: Self-signed or cert-manager certificates
- **External**: Cloudflare Edge certificates (Full/Strict mode)

### Access Control
- Cloudflare Access policies
- Kubernetes RBAC for gateway resources
- Service mesh authentication (if using Istio)

## Best Practices

### Resource Organization
- One HTTPRoute per service
- Group related routes in same namespace
- Use descriptive names and labels

### Domain Management
- Internal: `service.cluster.home.io`
- External: `service.cluster.lab.techdufus.com`
- Wildcard DNS for cluster domains

### Monitoring
- Gateway metrics exposed on :9090
- CloudFlare tunnel metrics
- HTTPRoute status conditions

### Backup and Recovery
- Export gateway configurations
- Document external DNS records
- Maintain Cloudflare tunnel tokens

## Contributing

When adding new services:

1. Create HTTPRoute using template
2. Test both internal and external access
3. Update documentation
4. Verify monitoring works
5. Submit PR with changes

## Support

For issues:
- Check logs: `kubectl logs -n nginx-gateway -l app.kubernetes.io/name=nginx-gateway`
- Verify Gateway API resources: `kubectl get gateways,httproutes -A`
- Review CLAUDE.md for common commands and troubleshooting