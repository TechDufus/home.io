# Cluster API Implementation for Home Lab

This directory contains a complete Cluster API (CAPI) implementation for managing Kubernetes clusters on Proxmox infrastructure. This provides an alternative to the Terraform + Ansible approach with native Kubernetes cluster lifecycle management.

## Quick Start

### 1. Bootstrap Management Cluster

```bash
cd kubernetes/capi/bootstrap
./install-capi.sh
```

### 2. Create Your First Cluster

```bash
# Development cluster
./kubernetes/capi/scripts/create-cluster.sh --name dev-cluster --env dev --install-addons

# Production cluster  
./kubernetes/capi/scripts/create-cluster.sh --name prod-cluster --env prod --install-addons
```

### 3. Install ArgoCD

```bash
./kubernetes/capi/scripts/install-argocd.sh --name dev-cluster
```

## Directory Structure

```
kubernetes/capi/
├── bootstrap/                 # Management cluster setup
│   ├── kind-cluster.yaml     # Kind cluster configuration
│   └── install-capi.sh       # Bootstrap script
├── providers/                 # CAPI provider configurations
│   ├── proxmox-provider.yaml # Proxmox provider setup
│   └── infrastructure-components.yaml
├── clusters/
│   ├── templates/            # Cluster templates
│   │   └── cluster-template.yaml
│   └── environments/         # Environment-specific clusters
│       ├── dev/              # Development environment
│       └── prod/             # Production environment
└── scripts/                  # Operational scripts
    ├── create-cluster.sh     # Create new clusters
    ├── delete-cluster.sh     # Delete clusters
    ├── scale-cluster.sh      # Scale cluster nodes
    └── install-argocd.sh     # Install ArgoCD
```

## Key Features

### 🚀 **Automated Cluster Lifecycle**
- **Declarative Management**: Kubernetes-native cluster definitions
- **Self-Healing**: Automatic reconciliation of desired state
- **Scaling**: Easy horizontal scaling of worker nodes
- **Upgrades**: Automated Kubernetes version upgrades

### 🔧 **Production-Ready Configuration**
- **High Availability**: Multi-master control plane support
- **Security**: Pod security standards and RBAC
- **Monitoring**: Built-in metrics and observability
- **Storage**: Persistent volume provisioning

### 🌐 **Multi-Cloud Ready**
- **Provider Abstraction**: Easy migration between cloud providers
- **Standardized APIs**: Consistent cluster management across environments
- **GitOps Integration**: Native Kubernetes manifest management

### 📊 **Operational Excellence**
- **Health Checks**: Automatic node replacement on failure
- **Resource Management**: CPU, memory, and storage optimization
- **Backup Integration**: Cluster and workload backup strategies

## Cluster Templates

### Development Environment
- **Control Plane**: 1 node (2 CPU, 4GB RAM, 30GB disk)
- **Workers**: 2 nodes (2 CPU, 4GB RAM, 50GB disk)
- **Features**: Verbose logging, development-friendly settings

### Production Environment
- **Control Plane**: 3 nodes (4 CPU, 8GB RAM, 50GB disk)
- **Workers**: 5 nodes (4 CPU, 8GB RAM, 100GB disk)
- **Features**: Audit logging, security hardening, monitoring

## Infrastructure Components

### Included in Cluster Creation
- **CNI**: Calico for pod networking
- **MetalLB**: LoadBalancer service support
- **Ingress-NGINX**: HTTP/HTTPS ingress controller
- **Local Path Provisioner**: Dynamic storage provisioning

### Optional Add-ons
- **ArgoCD**: GitOps continuous deployment
- **Prometheus Stack**: Monitoring and alerting
- **Cert-Manager**: Automatic TLS certificate management
- **External DNS**: Automatic DNS record management

## Common Operations

### Create a Cluster
```bash
./scripts/create-cluster.sh --name my-cluster --env dev
```

### Scale Workers
```bash
./scripts/scale-cluster.sh --name my-cluster --workers 5
```

### Delete a Cluster
```bash
./scripts/delete-cluster.sh --name my-cluster
```

### Upgrade Cluster
```bash
kubectl patch kubeadmcontrolplane my-cluster-control-plane \
  --type merge --patch '{"spec":{"version":"v1.29.1"}}'
```

## Comparison with Terraform + Ansible

| Aspect | CAPI | Terraform + Ansible |
|--------|------|---------------------|
| **Learning Curve** | Medium (K8s concepts) | Low (familiar tools) |
| **Automation** | High (built-in) | Medium (custom scripts) |
| **Day-2 Operations** | Excellent | Good |
| **Multi-Cloud** | Excellent | Provider-specific |
| **State Management** | K8s etcd | Terraform state |
| **GitOps Integration** | Native | External tooling |
| **Cluster Upgrades** | Automated | Manual process |

## When to Choose CAPI

### ✅ **Choose CAPI When:**
- You want Kubernetes-native cluster management
- Planning to manage multiple clusters
- Need automated lifecycle operations
- Prefer GitOps workflows
- Want future multi-cloud flexibility
- Have experience with Kubernetes concepts

### ⚠️ **Consider Alternatives When:**
- You need simple, one-time cluster creation
- Prefer direct VM control and customization
- Team is more familiar with traditional IaC tools
- You want minimal management cluster overhead

## Prerequisites

### Infrastructure
- Proxmox VE 7.x+ with API access
- Ubuntu 22.04 cloud-init template
- Network connectivity and DNS resolution
- Sufficient resources for management + workload clusters

### Tools
- Docker (for management cluster)
- kubectl
- Git
- SSH access to Proxmox

## Getting Started

1. **Read the Setup Guide**: See `docs/capi-setup-guide.md` for detailed instructions
2. **Bootstrap Management Cluster**: Run `bootstrap/install-capi.sh`
3. **Configure Proxmox**: Update provider credentials
4. **Create First Cluster**: Use creation scripts or apply manifests directly
5. **Install Applications**: Deploy ArgoCD and configure GitOps

## Support and Troubleshooting

- **Setup Guide**: `docs/capi-setup-guide.md`
- **Common Issues**: Check troubleshooting section in setup guide
- **Debug Commands**: Use `clusterctl describe cluster <name>` for diagnostics
- **Logs**: Check CAPI controller logs with `kubectl logs -n capi-system`

## Future Enhancements

- **Additional Providers**: AWS, Azure, GCP support
- **Advanced Networking**: Cilium CNI with advanced features
- **Security**: OPA Gatekeeper policy enforcement
- **Observability**: Complete monitoring stack deployment
- **Backup**: Velero cluster backup integration

This CAPI implementation provides a robust, scalable foundation for Kubernetes cluster management that grows with your infrastructure needs while maintaining operational simplicity.