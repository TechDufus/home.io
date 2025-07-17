# Development Talos Cluster

Terraform configuration for the development Talos Linux Kubernetes cluster on Proxmox VE.

## Architecture

- **Control Plane**: 1 node (4 CPU, 8GB RAM, 80GB disk)
- **Workers**: 2 nodes (4 CPU, 12GB RAM, 100GB disk)
- **Network**: 10.0.20.0/24 with MetalLB pool at .200-.230
- **CNI**: Flannel (default), configurable for Calico/Cilium
- **Storage**: Local-path provisioner for development workloads

## Prerequisites

- Proxmox VE with API access
- 1Password CLI configured with "Proxmox Terraform User" item
- Terraform >= 1.0, talosctl >= 1.7.6, kubectl >= 1.28

## Deployment

```bash
terraform init && terraform plan && terraform apply
```

Post-deployment, kubeconfig and talosconfig are automatically merged into your local configs.

## Multi-Machine Access

```bash
# Store kubeconfig in 1Password
op item create --category=Document --title="homelab-dev-kubeconfig" --vault="Personal" kubeconfig=@kubeconfig

# Access from another machine
op document get "homelab-dev-kubeconfig" --vault="Personal" > ~/.kube/config-homelab-dev
KUBECONFIG=~/.kube/config:~/.kube/config-homelab-dev kubectl config view --flatten > ~/.kube/config
```

## Configuration

Key variables in `terraform.tfvars`:
- `control_plane_ip`: Static IP for control plane (default: 10.0.20.10)
- `worker_nodes.count`: Number of workers (default: 2)
- VM IDs: Template 9200, Control Plane 200, Workers 210+

## State Management

```bash
# Sync Terraform state with 1Password
./scripts/tfstate push    # After terraform apply
./scripts/tfstate pull    # On new machine
./scripts/tfstate sync    # Smart sync based on timestamps
./scripts/tfstate status  # Check sync status
```

## Operations

```bash
# Scale workers
vim terraform.tfvars  # Update worker_nodes.count
terraform apply

# Access nodes
kubectl get nodes -o wide
talosctl -n 10.0.20.10 dashboard
talosctl -n 10.0.20.10 logs kubelet

# Destroy
terraform destroy
```

## Customization

- **CNI**: Edit `clusters.tf` to switch from Flannel to Calico/Cilium
- **Node count**: Adjust `worker_nodes.count` in `terraform.tfvars`
- **Machine configs**: Modify patches in `clusters.tf` for specialized configurations

## Notes

- Credentials managed via 1Password
- No SSH access - use `talosctl` for node management
- VM access keys pulled from GitHub (configured in module)
- State synced to 1Password for multi-machine access
