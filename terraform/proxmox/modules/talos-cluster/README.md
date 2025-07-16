# Talos Cluster Module

This module creates a complete Talos Linux Kubernetes cluster on Proxmox VE with a single Terraform configuration block. It abstracts away the complexity of creating templates, configuring nodes, bootstrapping the cluster, and extracting credentials.

## Features

- Single-block cluster definition with minimal required configuration
- Automatic IP address assignment from a base IP
- Flexible storage distribution for JBOD configurations
- Automatic template creation and management
- Complete cluster bootstrap and kubeconfig extraction
- Support for custom hardware specifications per node type
- Comprehensive outputs for external tooling integration

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| proxmox | ~> 0.66 |
| talos | ~> 0.7 |
| local | ~> 2.4 |

## Usage

### Basic Example

```hcl
module "dev_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name = "homelab-dev"
  base_ip      = "10.0.20.40"
  vm_id_start  = 200
  gateway      = "10.0.20.1"
}
```

This creates a cluster with:
- 1 control plane node at 10.0.20.40 (VM ID 200)
- 3 worker nodes at 10.0.20.41-43 (VM IDs 201-203)
- Talos template at VM ID 100 (auto-calculated)

### Storage Distribution (JBOD)

```hcl
module "prod_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name = "homelab-prod"
  base_ip      = "10.0.20.50"
  vm_id_start  = 300
  gateway      = "10.0.20.1"
  
  # Distribute nodes across different storage pools
  storage_mapping = {
    control_plane = "ssd-pool"      # Fast SSD for control plane
    worker-1      = "ssd-pool"      # Worker 1 on SSD
    worker-2      = "hdd-pool-1"    # Worker 2 on HDD 1
    worker-3      = "hdd-pool-2"    # Worker 3 on HDD 2
  }
}
```

### Advanced Configuration

```hcl
module "large_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name = "homelab-large"
  base_ip      = "10.0.20.60"
  vm_id_start  = 400
  gateway      = "10.0.20.1"
  
  # Custom worker count
  worker_count = 5
  
  # Custom hardware specifications
  control_plane_cores  = 8
  control_plane_memory = 16384
  control_plane_disk   = 120
  
  worker_cores  = 6
  worker_memory = 16384
  worker_disk   = 200
  
  # Custom networking
  network_vlan_id = 20
  dns_servers     = ["10.0.0.99", "10.0.0.98"]
  
  # Custom Kubernetes network ranges
  pod_subnet     = "10.244.0.0/16"
  service_subnet = "10.96.0.0/12"
  
  # Environment and tags
  environment = "prod"
  common_tags = ["homelab", "production", "kubernetes"]
}
```

### Using Module Outputs

```hcl
# Save kubeconfig to file
resource "local_file" "kubeconfig" {
  content  = module.dev_cluster.kubeconfig
  filename = "${path.module}/kubeconfig-${module.dev_cluster.cluster_name}"
  
  file_permission = "0600"
}

# Store kubeconfig in 1Password
resource "null_resource" "store_kubeconfig" {
  provisioner "local-exec" {
    command = <<-EOT
      echo '${module.dev_cluster.kubeconfig}' | op item create \
        --category=Document \
        --title="${module.dev_cluster.cluster_name}-kubeconfig" \
        --vault="Infrastructure"
    EOT
  }
}

# Calculate MetalLB IP pool based on cluster IPs
locals {
  metallb_start_ip = cidrhost("${module.dev_cluster.control_plane_ip}/24", 10)
  metallb_end_ip   = cidrhost("${module.dev_cluster.control_plane_ip}/24", 19)
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| base_ip | Starting IP address for the cluster | `string` | n/a | yes |
| vm_id_start | Starting VM ID for the cluster nodes | `number` | n/a | yes |
| gateway | Network gateway | `string` | n/a | yes |
| worker_count | Number of worker nodes | `number` | `3` | no |
| control_plane_cores | CPU cores for control plane | `number` | `4` | no |
| control_plane_memory | Memory in MB for control plane | `number` | `8192` | no |
| control_plane_disk | Disk size in GB for control plane | `number` | `80` | no |
| worker_cores | CPU cores per worker | `number` | `4` | no |
| worker_memory | Memory in MB per worker | `number` | `12288` | no |
| worker_disk | Disk size in GB per worker | `number` | `100` | no |
| proxmox_node | Proxmox node to deploy on | `string` | `"proxmox"` | no |
| network_bridge | Network bridge to use | `string` | `"vmbr0"` | no |
| network_vlan_id | VLAN ID (null for no VLAN) | `number` | `null` | no |
| subnet_mask | Subnet mask in CIDR notation | `number` | `24` | no |
| dns_servers | DNS servers | `list(string)` | `["10.0.0.99", "1.1.1.1", "1.0.0.1"]` | no |
| talos_version | Talos version to use | `string` | `"1.7.6"` | no |
| storage_pool | Default storage pool for VM disks | `string` | `"local-lvm"` | no |
| storage_mapping | Map nodes to specific storage pools | `map(string)` | `{}` | no |
| template_storage_pool | Storage pool for template/ISO storage | `string` | `"local"` | no |
| environment | Environment name | `string` | `"dev"` | no |
| full_clone | Use full clone instead of linked clone | `bool` | `false` | no |
| onboot | Start VMs on boot | `bool` | `true` | no |
| template_vm_id | VM ID for Talos template | `number` | `null` | no |
| common_tags | Tags to apply to all resources | `list(string)` | `["homelab"]` | no |
| pod_subnet | Pod network CIDR | `string` | `"10.244.0.0/16"` | no |
| service_subnet | Service network CIDR | `string` | `"10.96.0.0/12"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | The name of the created cluster |
| control_plane_ip | IP address of the control plane |
| worker_ips | List of worker node IPs |
| cluster_endpoint | Kubernetes API endpoint |
| kubeconfig | Generated kubeconfig for cluster access (sensitive) |
| talosconfig | Generated talosconfig for cluster management (sensitive) |
| vm_ids | Map of node names to VM IDs |
| machine_secrets | Talos machine secrets (sensitive) |
| template_vm_id | VM ID of the Talos template |
| node_details | Detailed information about all nodes |
| node_names | List of all node names |
| all_node_ips | List of all node IPs |
| network_config | Network configuration details |
| storage_mapping | Storage pool assignments for each node |

## Storage Distribution (JBOD)

The module supports distributing nodes across different storage pools, which is useful for:
- **Performance optimization**: Place control plane on fast SSD storage
- **Cost optimization**: Use cheaper HDD storage for worker nodes
- **Failure domain isolation**: Spread nodes across different physical disks

Example storage mapping:
```hcl
storage_mapping = {
  control_plane = "ssd-pool"      # Control plane on SSD
  worker-1      = "ssd-pool"      # First worker shares SSD
  worker-2      = "hdd-pool-1"    # Second worker on HDD 1
  worker-3      = "hdd-pool-2"    # Third worker on HDD 2
}
```

Unmapped nodes fall back to the default `storage_pool` variable.

## IP Address Management

The module automatically assigns IP addresses sequentially:
- Control plane: Gets the `base_ip` exactly
- Worker 1: `base_ip + 1`
- Worker 2: `base_ip + 2`
- And so on...

Example with `base_ip = "10.0.20.40"`:
- Control plane: 10.0.20.40
- Worker 1: 10.0.20.41
- Worker 2: 10.0.20.42
- Worker 3: 10.0.20.43

## VM ID Management

VM IDs are assigned sequentially from `vm_id_start`:
- Control plane: `vm_id_start`
- Worker 1: `vm_id_start + 1`
- Worker 2: `vm_id_start + 2`
- Template: `vm_id_start - 100` (unless explicitly set)

## Multiple Clusters

You can deploy multiple clusters in the same Terraform configuration:

```hcl
module "dev_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name = "dev"
  base_ip      = "10.0.20.40"
  vm_id_start  = 200
  gateway      = "10.0.20.1"
}

module "prod_cluster" {
  source = "./modules/talos-cluster"
  
  cluster_name = "prod"
  base_ip      = "10.0.20.50"
  vm_id_start  = 300
  gateway      = "10.0.20.1"
  worker_count = 5
}
```

## Limitations

- Single control plane only (no HA control plane support yet)
- Fixed network interface name (eth0)
- No custom CNI selection (uses Talos default - Flannel)
- No GPU node support
- Template must be accessible via SSH for creation

## Troubleshooting

### Template Creation Fails
- Ensure the Proxmox node can access the internet to download Talos images
- Verify the `template_storage_pool` exists and has enough space
- Check SSH access to the Proxmox node

### Bootstrap Fails
- Ensure the control plane node has started successfully
- Check network connectivity between Terraform and the control plane IP
- Verify no IP conflicts exist

### Storage Pool Not Found
- Ensure storage pool names match exactly with Proxmox configuration
- Use `pvesm status` on Proxmox to list available storage pools

## References

- [Talos Linux Documentation](https://www.talos.dev/)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)