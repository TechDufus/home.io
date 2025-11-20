# Development Environment - Talos Kubernetes Cluster

This directory contains Terraform configuration for deploying a development Talos Linux Kubernetes cluster on Proxmox VE.

## Overview

This environment creates a production-grade Kubernetes cluster using:
- **Talos Linux**: Immutable Kubernetes OS
- **Proxmox VE**: Virtualization platform
- **1Password**: Secure credential management
- **Terraform**: Infrastructure as code

## Prerequisites

### Required Tools
- [Terraform](https://terraform.io) >= 1.0
- [talosctl](https://www.talos.dev/v1.7/introduction/getting-started/) >= 1.7.6
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [1Password CLI](https://developer.1password.com/docs/cli/) configured

### Proxmox Setup
- Proxmox VE node with API access
- 1Password item named "Proxmox Terraform User" in "Personal" vault containing:
  - URL: Proxmox API endpoint (e.g., `https://proxmox.home.io:8006/api2/json`)
  - Username: Terraform user with VM creation privileges
  - Password: User password

## Quick Start

### 1. Configure Variables
```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your environment settings
vim terraform.tfvars
```

### 2. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy cluster
terraform apply
```

### 3. Access Cluster
After deployment, configurations are automatically merged:
```bash
# Switch to cluster context
kubectl config use-context homelab-dev

# Verify cluster health
kubectl get nodes

# Or use talosctl directly
talosctl -n 10.0.20.10 health
```

## Multi-Machine Access with 1Password

The `kubestate` script provides automated syncing of kubeconfigs to/from 1Password, similar to the `tfstate` script for Terraform state.

### Automated Workflow (Recommended)

```bash
# From the dev environment directory
cd terraform/proxmox/environments/dev

# Push kubeconfig to 1Password (after terraform apply)
../scripts/kubestate push dev

# On another machine: Pull and auto-merge kubeconfig
../scripts/kubestate pull dev

# Pull to specific file without merging
../scripts/kubestate pull dev --output ~/Downloads/cluster.yaml

# Extract to terraform directory (makes this machine the new source)
../scripts/kubestate extract dev

# Smart sync based on timestamps (auto push/pull)
../scripts/kubestate sync dev

# Check sync status
../scripts/kubestate status dev

# List all kubeconfigs in 1Password
../scripts/kubestate list
```

### Key Features

- **Intelligent Merging**: `pull` automatically merges with existing `~/.kube/config` preserving other contexts
- **Smart Sync**: `sync` automatically determines push/pull based on timestamps
- **Extract to Source**: `extract` downloads to terraform directory (solves "Machine A dies" scenario)
- **Custom Output**: `pull --output <file>` downloads to specific file without merging
- **Backup Support**: `--backup` flag creates backups before merging
- **Force Operations**: `--force` flag skips confirmation prompts

### Configuration

The script uses these defaults (override with environment variables):
- Vault: `cicd` (set `KUBECONFIG_VAULT` to change)
- Item prefix: `kubeconfig` (set `KUBECONFIG_PREFIX` to change)
- Auto-detected environment from directory

### Manual Method (Legacy)

If you prefer manual operations:
```bash
# Save to 1Password
op item create --category=Document \
  --title="kubeconfig-dev" \
  --vault="cicd" \
  kubeconfig=@terraform/proxmox/environments/dev/kubeconfig

# Download and merge manually
op document get "kubeconfig-dev" --vault="cicd" > ~/.kube/config-homelab-dev
KUBECONFIG=~/.kube/config:~/.kube/config-homelab-dev kubectl config view --flatten > ~/.kube/config.tmp
mv ~/.kube/config.tmp ~/.kube/config
kubectl config use-context homelab-dev
```

## Configuration

### Required Variables
Edit `terraform.tfvars` with your specific values:

```hcl
# Basic Configuration
environment  = "dev"
cluster_name = "homelab-dev"
proxmox_node = "your-proxmox-node"

# Network Configuration (adjust for your network)
control_plane_ip = "10.0.20.10"
subnet_mask      = 24
gateway          = "10.0.20.1"
dns_servers      = ["10.0.0.99", "1.1.1.1"]

# Hardware Configuration
control_plane_nodes = {
  cpu     = 4
  memory  = 8192
  disk_gb = 80
}

worker_nodes = {
  count   = 2
  cpu     = 4
  memory  = 12288
  disk_gb = 100
}
```

### VM ID Allocation
Default VM IDs (adjust to avoid conflicts):
- Template: 9200
- Control Plane: 200
- Workers: 210, 211, etc.

## Architecture

### Cluster Components
- **1 Control Plane Node**: Kubernetes API server, etcd, scheduler
- **2 Worker Nodes**: Application workload execution
- **Talos Template**: Shared base image for all nodes

### Network Layout
- Control Plane: Static IP (configured)
- Workers: DHCP or calculated IPs (.11, .12, etc.)
- Pod Network: `10.244.0.0/16` (Flannel)
- Service Network: `10.96.0.0/12`

### Storage Configuration
- VM Disks: `local-lvm` (configurable)
- Templates: `local` (configurable)
- Linked Clones: Enabled for faster deployment

## Module Dependencies

This environment uses shared modules:
- `../../modules/talos-template`: Talos image management
- `../../modules/talos-node`: VM creation and configuration

## Generated Files

After deployment, these files are created:
- `kubeconfig`: Kubernetes cluster access
- `talosconfig`: Talos OS management
- `terraform.tfstate`: Terraform state (local backend)

Configurations are automatically merged into:
- `~/.kube/config`: Kubernetes contexts
- `~/.talos/config`: Talos contexts

## Management Commands

### Cluster Operations
```bash
# Scale worker nodes (edit terraform.tfvars, then apply)
terraform apply

# Destroy cluster
terraform destroy

# View cluster status
kubectl get nodes -o wide
talosctl -n 10.0.20.10 dashboard
```

### Troubleshooting
```bash
# Check Talos logs
talosctl -n 10.0.20.10 logs controller-manager

# Restart services
talosctl -n 10.0.20.10 restart

# Reset and reconfigure node
talosctl -n 10.0.20.10 reset --graceful
```

## Customization

### Adding CNI Plugins
Edit `main.tf` to configure alternative CNI:
```hcl
# In data.talos_machine_configuration.control_plane
cluster = {
  network = {
    cni = {
      name = "calico"  # or "cilium"
    }
  }
}
```

### Additional Nodes
Increase `worker_nodes.count` in `terraform.tfvars` and apply.

### Custom Machine Configs
Modify config patches in `main.tf` for specialized node configurations.

## Security Notes

- All credentials managed via 1Password
- VM access via SSH keys from GitHub
- Talos provides immutable, minimal attack surface
- No SSH access to nodes (use `talosctl` for management)

## Next Steps

After cluster deployment:
1. Install ingress controller (NGINX, Traefik)
2. Configure persistent storage (Longhorn, local-path)
3. Deploy monitoring stack (Prometheus, Grafana)
4. Set up GitOps with ArgoCD or Flux

## Related Documentation

- [Talos Documentation](https://www.talos.dev/v1.7/)
- [Project Architecture](../../../../README.md)
