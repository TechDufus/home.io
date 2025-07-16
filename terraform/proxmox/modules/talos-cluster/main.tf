# Talos Cluster Module
# This module creates a complete Talos Linux Kubernetes cluster on Proxmox

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Calculate derived values for use throughout the module
locals {
  # Template ID: use provided or calculate from vm_id_start
  template_vm_id = var.template_vm_id != null ? var.template_vm_id : var.vm_id_start - 100

  # IP assignments
  control_plane_ip = var.base_ip

  # Calculate the host number of the base IP within its network
  # Then add offset for each worker
  base_network  = cidrsubnet("${var.base_ip}/${var.subnet_mask}", 0, 0)
  base_host_num = parseint(split(".", var.base_ip)[3], 10)

  worker_ips = [for i in range(var.worker_count) :
    cidrhost(local.base_network, local.base_host_num + i + 1)
  ]

  # Storage mapping with fallback to default
  control_plane_storage = lookup(var.storage_mapping, "control_plane", var.storage_pool)

  worker_storage = [for i in range(var.worker_count) :
    lookup(var.storage_mapping, "worker-${i + 1}", var.storage_pool)
  ]

  # Common tags for all resources
  common_tags = concat(var.common_tags, ["talos", "kubernetes", var.environment])
}

# Create Talos template if needed
module "template" {
  source = "../talos-template"

  # Template configuration
  template_vm_id = local.template_vm_id
  talos_version  = var.talos_version

  # Proxmox configuration
  proxmox_node          = var.proxmox_node
  template_storage_pool = var.template_storage_pool
  vm_storage_pool       = var.storage_pool

  # Tagging
  common_tags = concat(local.common_tags, ["template"])
}

# Generate Talos cluster secrets
resource "talos_machine_secrets" "cluster" {}

# Generate machine configuration for control plane
data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          podSubnets     = [var.pod_subnet]
          serviceSubnets = [var.service_subnet]
        }
        proxy = {
          disabled = false
        }
      }
      machine = {
        network = {
          hostname = "${var.cluster_name}-cp"
          interfaces = [{
            interface = "eth0"
            addresses = ["${local.control_plane_ip}/${var.subnet_mask}"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
          }]
          nameservers = var.dns_servers
        }
        time = {
          servers = ["time.cloudflare.com"]
        }
        features = {
          rbac = true
        }
        sysctls = {
          "net.core.somaxconn"          = "65535"
          "net.core.netdev_max_backlog" = "5000"
        }
        kubelet = {
          extraArgs = {
            "feature-gates" = "GracefulNodeShutdown=true"
          }
        }
      }
    })
  ]
}

# Generate machine configuration for worker nodes (individual configs for unique hostnames)
data "talos_machine_configuration" "worker" {
  count = var.worker_count

  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = "${var.cluster_name}-worker-${count.index + 1}"
          interfaces = [{
            interface = "eth0"
            addresses = ["${local.worker_ips[count.index]}/${var.subnet_mask}"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
          }]
          nameservers = var.dns_servers
        }
        time = {
          servers = ["time.cloudflare.com"]
        }
        sysctls = {
          "net.core.somaxconn"          = "65535"
          "net.core.netdev_max_backlog" = "5000"
        }
        kubelet = {
          extraArgs = {
            "feature-gates" = "GracefulNodeShutdown=true"
          }
        }
      }
    })
  ]
}

# Create Control Plane Node
module "control_plane" {
  source = "../talos-node"

  # Explicit dependency on template creation
  depends_on = [module.template]

  # Node Configuration
  node_name = "${var.cluster_name}-cp"
  node_role = "controlplane"
  vm_id     = var.vm_id_start

  # Template Configuration - use the template we manage
  template_vm_id = module.template.template_id
  full_clone     = var.full_clone

  # Hardware Configuration
  cpu_cores    = var.control_plane_cores
  memory_mb    = var.control_plane_memory
  disk_size_gb = var.control_plane_disk
  cpu_type     = "x86-64-v2-AES"

  # Proxmox Configuration
  proxmox_node = var.proxmox_node
  storage_pool = local.control_plane_storage

  # Network Configuration
  network_bridge  = var.network_bridge
  network_vlan_id = var.network_vlan_id
  ip_address      = local.control_plane_ip
  subnet_mask     = var.subnet_mask
  gateway         = var.gateway
  dns_servers     = var.dns_servers

  # Talos Configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.control_plane.machine_configuration

  # VM Settings
  onboot = var.onboot

  # Tagging
  common_tags = local.common_tags
}

# Create Worker Nodes
module "workers" {
  source = "../talos-node"
  count  = var.worker_count

  # Explicit dependency on template creation
  depends_on = [module.template]

  # Node Configuration
  node_name = "${var.cluster_name}-worker-${count.index + 1}"
  node_role = "worker"
  vm_id     = var.vm_id_start + count.index + 1

  # Template Configuration - use the template we manage
  template_vm_id = module.template.template_id
  full_clone     = var.full_clone

  # Hardware Configuration
  cpu_cores    = var.worker_cores
  memory_mb    = var.worker_memory
  disk_size_gb = var.worker_disk
  cpu_type     = "x86-64-v2-AES"

  # Proxmox Configuration
  proxmox_node = var.proxmox_node
  storage_pool = local.worker_storage[count.index]

  # Network Configuration
  network_bridge  = var.network_bridge
  network_vlan_id = var.network_vlan_id
  ip_address      = local.worker_ips[count.index]
  subnet_mask     = var.subnet_mask
  gateway         = var.gateway
  dns_servers     = var.dns_servers

  # Talos Configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.worker[count.index].machine_configuration

  # VM Settings
  onboot = var.onboot

  # Tagging
  common_tags = local.common_tags
}

# Bootstrap Talos cluster (only on control plane, once)
resource "talos_machine_bootstrap" "cluster" {
  depends_on = [module.control_plane]

  node                 = local.control_plane_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

# Extract kubeconfig from cluster
resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [talos_machine_bootstrap.cluster]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = local.control_plane_ip
}