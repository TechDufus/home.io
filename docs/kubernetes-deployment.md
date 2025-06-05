# Kubernetes Cluster Deployment Guide

This guide documents the complete Kubernetes cluster deployment process for the home.io infrastructure using Terraform and Ansible.

## Architecture Overview

The solution uses:
- **Terraform**: Provision VMs on Proxmox hypervisor
- **Cloud-init**: Initial VM configuration (SSH keys, packages)
- **Ansible**: Kubernetes installation and configuration
- **ArgoCD**: GitOps-based application deployment

## Prerequisites

1. **Proxmox Setup**
   - Ubuntu 22.04 cloud-init template (`ubuntu-2204-cloud`)
   - SSH access to Proxmox host
   - Sufficient resources for K8s nodes

2. **Local Requirements**
   - Terraform installed
   - Ansible installed
   - kubectl installed
   - SSH key pair (`~/.ssh/id_rsa`)

3. **Configuration Files**
   - `/terraform/proxmox/creds.auto.tfvars` with Proxmox credentials
   - `~/.ansible-vault/vault.secret` with Ansible vault password

## Deployment Process

### Step 1: Define Kubernetes Nodes

Add the following to your `terraform/proxmox/vars.auto.tfvars`:

```hcl
# Kubernetes version
k8s_version = "1.29.0"

# Network configuration
pod_cidr     = "10.244.0.0/16"
service_cidr = "10.96.0.0/12"

# Control plane nodes
k8s_control_plane_nodes = {
  "k8s-control-1" = {
    hostname   = "k8s-control-1"
    vmid       = "120"
    ip_address = "10.0.0.20"
    cpu_cores  = 4
    memory     = 8192
    disk_size  = "50G"
  }
}

# Worker nodes
k8s_worker_nodes = {
  "k8s-worker-1" = {
    hostname   = "k8s-worker-1"
    vmid       = "121"
    ip_address = "10.0.0.21"
    cpu_cores  = 4
    memory     = 8192
    disk_size  = "100G"
  }
  "k8s-worker-2" = {
    hostname   = "k8s-worker-2"
    vmid       = "122"
    ip_address = "10.0.0.22"
    cpu_cores  = 4
    memory     = 8192
    disk_size  = "100G"
  }
  "k8s-worker-3" = {
    hostname   = "k8s-worker-3"
    vmid       = "123"
    ip_address = "10.0.0.23"
    cpu_cores  = 4
    memory     = 8192
    disk_size  = "100G"
  }
}
```

### Step 2: Deploy Infrastructure

```bash
cd terraform/proxmox
terraform init
terraform plan
terraform apply
```

After deployment, note the MAC addresses from the output and update `vars.auto.tfvars`:

```hcl
k8s_control_plane_nodes = {
  "k8s-control-1" = {
    # ... existing config ...
    macaddr = "XX:XX:XX:XX:XX:XX"  # Add this line
  }
}
```

### Step 3: Update Ansible Inventory

Edit `ansible/inventory/k8s/hosts.ini` with the correct IP addresses:

```ini
[k8s_control_plane]
k8s-control-1 ansible_host=10.0.0.20

[k8s_workers]
k8s-worker-1 ansible_host=10.0.0.21
k8s-worker-2 ansible_host=10.0.0.22
k8s-worker-3 ansible_host=10.0.0.23
```

### Step 4: Run Bootstrap Script

```bash
./scripts/bootstrap-k8s-cluster.sh
```

Or run manually:

```bash
# Configure Kubernetes cluster
cd ansible
ansible-playbook -i inventory/k8s/hosts.ini playbooks/k8s-cluster.yaml

# Deploy ArgoCD
ansible-playbook -i inventory/k8s/hosts.ini playbooks/k8s-cluster.yaml --tags argocd
```

### Step 5: Access the Cluster

```bash
# Copy kubeconfig
scp techdufus@10.0.0.20:.kube/config ~/.kube/config-home-k8s
export KUBECONFIG=~/.kube/config-home-k8s

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

## ArgoCD Configuration

### Access ArgoCD

1. Get admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. Access UI:
   - URL: `https://<control-plane-ip>:30443`
   - Username: `admin`
   - Password: (from step 1)

3. Login via CLI:
   ```bash
   argocd login <control-plane-ip>:30443 --insecure
   ```

### Configure Repository

ArgoCD is pre-configured to sync from:
- Repository: `https://github.com/techdufus/home.io`
- Path: `kubernetes/apps`
- Branch: `main`

## Application Deployment

Applications are managed through ArgoCD using the app-of-apps pattern:

1. **Root App**: `kubernetes/apps/root-app.yaml`
2. **Infrastructure Apps**: `kubernetes/apps/infrastructure.yaml`
   - MetalLB (Load Balancer)
   - Ingress-NGINX
   - Cert-Manager

### Adding New Applications

1. Create application manifests in `kubernetes/apps/`
2. Reference them in the root app or create a new app project
3. Commit and push to Git
4. ArgoCD will automatically sync

## Integration with Existing Infrastructure

### Terraform Integration

The K8s modules follow the same patterns as existing modules:
- Modular design for reusability
- Cloud-init for initial configuration
- MAC address management for stable networking

### Ansible Integration

The K8s roles integrate with existing patterns:
- Common role structure
- Vault for secrets management
- Tag-based execution

### Network Integration

- Uses existing Pi-hole DNS servers
- Integrates with home.io domain
- Compatible with VLAN configuration

## Maintenance Tasks

### Cluster Upgrades

```bash
# Update k8s_version in vars.auto.tfvars
# Run Ansible playbook with upgrade tag
ansible-playbook -i inventory/k8s/hosts.ini playbooks/k8s-cluster.yaml --tags k8s-upgrade
```

### Backup ETCD

Enable in `ansible/roles/k8s-control-plane/defaults/main.yml`:
```yaml
etcd_backup_enabled: true
etcd_backup_schedule: "0 2 * * *"
```

### Scale Workers

1. Add new worker definition to `vars.auto.tfvars`
2. Run `terraform apply`
3. Update Ansible inventory
4. Run worker playbook

## Troubleshooting

### Common Issues

1. **Nodes not joining**: Check firewall rules and network connectivity
2. **Pods not scheduling**: Verify CNI plugin installation
3. **ArgoCD sync failures**: Check repository access and credentials

### Debug Commands

```bash
# Check node status
kubectl describe node <node-name>

# Check pod logs
kubectl logs -n <namespace> <pod-name>

# Check cluster events
kubectl get events -A --sort-by='.lastTimestamp'
```

## Security Considerations

1. **Network Security**
   - K8s API secured with TLS
   - NodePort services limited to necessary ports
   - Network policies for pod-to-pod communication

2. **Access Control**
   - RBAC enabled by default
   - ArgoCD configured with minimal permissions
   - SSH key-based authentication

3. **Secrets Management**
   - Ansible Vault for deployment secrets
   - K8s secrets for runtime configuration
   - Regular rotation recommended