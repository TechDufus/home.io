# Cluster API (CAPI) Setup Guide

This comprehensive guide walks you through setting up and managing Kubernetes clusters using Cluster API with the Proxmox provider for your home lab infrastructure.

## Overview

Cluster API (CAPI) provides declarative APIs and tooling to simplify provisioning, upgrading, and operating multiple Kubernetes clusters. This implementation uses:

- **Management Cluster**: Kind cluster running CAPI controllers
- **Infrastructure Provider**: Proxmox for VM provisioning
- **Bootstrap Provider**: kubeadm for node initialization
- **Control Plane Provider**: kubeadm for control plane management

## Architecture Benefits

### Why Choose CAPI over Terraform + Ansible?

| Feature | CAPI | Terraform + Ansible |
|---------|------|---------------------|
| **Declarative Management** | ✅ Native K8s resources | ⚠️ Requires state management |
| **Self-Healing** | ✅ Automatic reconciliation | ❌ Manual intervention needed |
| **Cluster Lifecycle** | ✅ Automated upgrades/scaling | ⚠️ Manual process |
| **GitOps Integration** | ✅ Native K8s manifests | ⚠️ Additional tooling needed |
| **Multi-Cloud Ready** | ✅ Provider abstraction | ❌ Provider-specific code |
| **Day-2 Operations** | ✅ Built-in automation | ⚠️ Custom automation required |

### Trade-offs

**CAPI Advantages:**
- Kubernetes-native cluster management
- Automated lifecycle operations
- Provider-agnostic approach
- Built-in monitoring and observability
- GitOps-friendly declarative configuration

**CAPI Considerations:**
- Additional complexity for management cluster
- Learning curve for CAPI concepts
- Dependency on management cluster availability
- Less direct control over individual VMs

## Prerequisites

### Infrastructure Requirements

1. **Proxmox VE 7.x+** with API access
2. **VM Template** prepared for Kubernetes nodes:
   - Ubuntu 22.04 LTS recommended
   - Cloud-init enabled
   - SSH keys configured
   - Docker/containerd pre-installed (optional)

3. **Network Configuration**:
   - Static IP range for cluster nodes
   - DNS resolution for cluster endpoints
   - Internet access for downloading components

### Local Tools

- Docker (for Kind management cluster)
- kubectl
- Git

## Step 1: Bootstrap the Management Cluster

### 1.1 Run the Bootstrap Script

```bash
cd kubernetes/capi/bootstrap
./install-capi.sh
```

This script will:
- Install required tools (kind, kubectl, clusterctl)
- Create Kind management cluster
- Install CAPI core components
- Install Proxmox infrastructure provider
- Configure Proxmox credentials

### 1.2 Verify Installation

```bash
# Check management cluster
kubectl cluster-info

# Verify CAPI providers
clusterctl describe cluster

# Check provider status
kubectl get providers -A
```

## Step 2: Configure Proxmox Integration

### 2.1 Prepare VM Template

Create a VM template in Proxmox for Kubernetes nodes:

```bash
# Example template creation (adjust for your setup)
# 1. Create VM with Ubuntu 22.04
# 2. Install cloud-init
# 3. Configure SSH keys
# 4. Convert to template
```

### 2.2 Update Provider Configuration

Edit `kubernetes/capi/providers/proxmox-provider.yaml`:

```yaml
# Update these values for your environment
data:
  endpoint: "https://your-proxmox.home.io:8006/api2/json"
  username: "your-username@pam"
  password: "your-password"
  storage: "your-storage"
  bridge: "your-bridge"
```

### 2.3 Apply Provider Configuration

```bash
kubectl apply -f kubernetes/capi/providers/proxmox-provider.yaml
```

## Step 3: Create Your First Cluster

### 3.1 Using the Creation Script

```bash
# Create a development cluster
./kubernetes/capi/scripts/create-cluster.sh \
  --name dev-cluster \
  --env dev \
  --install-addons

# Create a production cluster
./kubernetes/capi/scripts/create-cluster.sh \
  --name prod-cluster \
  --env prod \
  --install-addons
```

### 3.2 Manual Cluster Creation

```bash
# Apply cluster manifests directly
kubectl apply -f kubernetes/capi/clusters/environments/dev/cluster.yaml

# Wait for cluster to be ready
kubectl wait --for=condition=Ready cluster dev-cluster --timeout=1200s
```

### 3.3 Get Cluster Access

```bash
# Retrieve kubeconfig
clusterctl get kubeconfig dev-cluster > ~/.kube/config-dev-cluster

# Access the cluster
export KUBECONFIG=~/.kube/config-dev-cluster
kubectl get nodes
```

## Step 4: Install ArgoCD on Workload Cluster

### 4.1 Using the Installation Script

```bash
./kubernetes/capi/scripts/install-argocd.sh \
  --name dev-cluster \
  --repo https://github.com/techdufus/home.io
```

### 4.2 Access ArgoCD

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access via browser
# https://argocd-dev-cluster.home.io
```

## Step 5: Day-2 Operations

### 5.1 Scaling Clusters

```bash
# Scale workers
./kubernetes/capi/scripts/scale-cluster.sh \
  --name dev-cluster \
  --workers 5

# Monitor scaling
kubectl get machinedeployment dev-cluster-workers -w
```

### 5.2 Cluster Upgrades

```bash
# Upgrade Kubernetes version
kubectl patch kubeadmcontrolplane dev-cluster-control-plane \
  --type merge \
  --patch '{"spec":{"version":"v1.29.1"}}'

# Upgrade worker nodes
kubectl patch machinedeployment dev-cluster-workers \
  --type merge \
  --patch '{"spec":{"template":{"spec":{"version":"v1.29.1"}}}}'
```

### 5.3 Adding Node Pools

```bash
# Create GPU node pool
cat <<EOF | kubectl apply -f -
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  name: dev-cluster-gpu-workers
  namespace: default
spec:
  clusterName: dev-cluster
  replicas: 2
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: dev-cluster
      pool: gpu-pool
  template:
    metadata:
      labels:
        cluster.x-k8s.io/cluster-name: dev-cluster
        pool: gpu-pool
    spec:
      clusterName: dev-cluster
      version: v1.29.0
      # ... rest of configuration
EOF
```

## Step 6: Multi-Cloud Preparation

### 6.1 Provider-Agnostic Configuration

Structure your cluster definitions to be easily portable:

```yaml
# Use environment variables for provider-specific values
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: ${CLUSTER_NAME}
spec:
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    kind: ${INFRASTRUCTURE_KIND}  # ProxmoxCluster, AWSCluster, etc.
    name: ${CLUSTER_NAME}
```

### 6.2 Future Cloud Providers

When ready to expand to cloud providers:

```bash
# Initialize additional providers
clusterctl init --infrastructure aws
clusterctl init --infrastructure azure
clusterctl init --infrastructure gcp
```

## Troubleshooting

### Common Issues

#### 1. Management Cluster Issues

```bash
# Check Kind cluster status
kind get clusters

# Restart management cluster
kind delete cluster --name capi-management
./kubernetes/capi/bootstrap/install-capi.sh
```

#### 2. Proxmox Connection Issues

```bash
# Verify credentials
kubectl get secret proxmox-credentials -n capmox-system -o yaml

# Check provider logs
kubectl logs -n capmox-system -l control-plane=controller-manager
```

#### 3. Cluster Creation Failures

```bash
# Check cluster status
kubectl describe cluster dev-cluster

# Check machine status
kubectl get machines -l cluster.x-k8s.io/cluster-name=dev-cluster

# Check infrastructure resources
kubectl get proxmoxmachines
kubectl get proxmoxclusters
```

#### 4. Node Join Issues

```bash
# Check bootstrap configuration
kubectl describe kubeadmconfig

# SSH to node and check cloud-init
ssh techdufus@node-ip
sudo cloud-init status
journalctl -u cloud-init
```

### Debug Commands

```bash
# Enable verbose logging
export CAPI_LOG_LEVEL=debug

# Describe cluster resources
clusterctl describe cluster dev-cluster

# Get cluster events
kubectl get events --sort-by='.lastTimestamp'

# Check provider status
kubectl get providers -A
```

## Best Practices

### 1. Management Cluster

- **High Availability**: Use external management cluster for production
- **Backup**: Regular etcd backups of management cluster
- **Monitoring**: Monitor CAPI controller health
- **Updates**: Keep CAPI components updated

### 2. Workload Clusters

- **Resource Planning**: Size nodes appropriately for workloads
- **Network Security**: Use network policies and firewalls
- **Storage**: Plan for persistent storage requirements
- **Monitoring**: Deploy observability stack early

### 3. GitOps Integration

- **Version Control**: Store all cluster definitions in Git
- **Environment Promotion**: Use branches for environment progression
- **Secret Management**: Use sealed secrets or external secret operators
- **Validation**: Implement CI/CD for cluster configuration validation

### 4. Security

- **RBAC**: Configure appropriate RBAC policies
- **Network Policies**: Implement pod-to-pod communication controls
- **Pod Security Standards**: Enforce pod security policies
- **Audit Logging**: Enable and monitor audit logs

## Advanced Configuration

### Custom Machine Templates

```yaml
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: high-memory-template
spec:
  template:
    spec:
      hardware:
        memory:
          size: "32768M"  # 32GB RAM
        cpu:
          cores: 8
        disk:
          - storage: "nvme-pool"
            size: "200G"
            type: "scsi"
```

### Cluster Resource Sets

Deploy additional components automatically:

```yaml
apiVersion: addons.cluster.x-k8s.io/v1beta1
kind: ClusterResourceSet
metadata:
  name: cni-installation
spec:
  strategy: ApplyOnce
  clusterSelector:
    matchLabels:
      cni: calico
  resources:
    - name: calico-cni
      kind: ConfigMap
```

### Machine Health Checks

Automatic node replacement:

```yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineHealthCheck
metadata:
  name: dev-cluster-worker-health
spec:
  clusterName: dev-cluster
  selector:
    matchLabels:
      pool: worker-pool
  unhealthyConditions:
    - type: Ready
      status: Unknown
      timeout: 300s
    - type: Ready
      status: "False"
      timeout: 300s
  maxUnhealthy: 40%
  nodeStartupTimeout: 20m
```

## Migration from Terraform + Ansible

### 1. Assessment

- **Inventory Current Infrastructure**: Document existing VMs and configurations
- **Identify Dependencies**: Map service dependencies and networking
- **Plan Migration**: Determine migration order and rollback strategy

### 2. Parallel Deployment

- **Deploy CAPI alongside existing infrastructure**
- **Migrate services gradually**
- **Validate functionality at each step**

### 3. Cutover

- **DNS Updates**: Point services to new clusters
- **Load Balancer Updates**: Update upstream configurations
- **Monitoring**: Ensure observability continues

## Conclusion

Cluster API provides a powerful, Kubernetes-native approach to cluster lifecycle management that offers significant advantages for home lab environments ready to adopt cloud-native practices. While it introduces additional complexity compared to traditional IaC approaches, the benefits of declarative management, automated operations, and multi-cloud portability make it an excellent choice for environments that prioritize:

- **Operational Excellence**: Automated cluster lifecycle management
- **Scalability**: Easy cluster creation and scaling
- **Consistency**: Standardized cluster configurations
- **Future-Proofing**: Cloud provider agnostic approach

The implementation provided gives you a production-ready foundation that can scale from home lab experimentation to enterprise-grade cluster management.