# Talos Kubernetes Cluster Module
# Manages the complete lifecycle of a Talos Kubernetes cluster

terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
  }
}

# Generate Talos cluster secrets (shared across all nodes)
resource "talos_machine_secrets" "cluster" {}

# Generate machine configuration for control plane nodes
data "talos_machine_configuration" "control_plane" {
  count = var.control_plane_count

  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_plane_vip != "" ? var.control_plane_vip : var.control_plane_ips[0]}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          podSubnets     = var.pod_subnets
          serviceSubnets = var.service_subnets
        }
        proxy = {
          disabled = var.disable_kube_proxy
        }
      }
      machine = {
        network = {
          hostname = "${var.cluster_name}-cp-${count.index + 1}"
          interfaces = [{
            interface = "eth0"
            addresses = ["${var.control_plane_ips[count.index]}/${var.subnet_mask}"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
            vip = var.control_plane_vip != "" && count.index == 0 ? {
              ip = var.control_plane_vip
            } : null
          }]
          nameservers = var.dns_servers
        }
        time = {
          servers = var.ntp_servers
        }
        features = {
          rbac = true
        }
        sysctls = merge(
          {
            "net.core.somaxconn"          = "65535"
            "net.core.netdev_max_backlog" = "5000"
          },
          var.additional_sysctls
        )
        kubelet = {
          extraArgs = merge(
            {
              "feature-gates" = join(",", var.kubelet_feature_gates)
            },
            var.kubelet_extra_args
          )
        }
      }
    })
  ]
}

# Generate machine configuration for worker nodes
data "talos_machine_configuration" "worker" {
  count = var.worker_count

  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.control_plane_vip != "" ? var.control_plane_vip : var.control_plane_ips[0]}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          podSubnets     = var.pod_subnets
          serviceSubnets = var.service_subnets
        }
      }
      machine = {
        network = {
          hostname = "${var.cluster_name}-worker-${count.index + 1}"
          interfaces = [{
            interface = "eth0"
            addresses = var.worker_ips != null ? ["${var.worker_ips[count.index]}/${var.subnet_mask}"] : []
            dhcp      = var.worker_ips == null ? true : false
            routes = var.worker_ips != null ? [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }] : []
          }]
          nameservers = var.dns_servers
        }
        time = {
          servers = var.ntp_servers
        }
        features = {
          rbac = true
        }
        sysctls = merge(
          {
            "net.core.somaxconn"          = "65535"
            "net.core.netdev_max_backlog" = "5000"
          },
          var.additional_sysctls
        )
      }
    })
  ]
}

# Control plane nodes
module "control_plane" {
  source = "../talos-node"
  count  = var.control_plane_count

  # Node identity
  node_name = "${var.cluster_name}-cp-${count.index + 1}"
  node_role = "controlplane"
  vm_id     = var.control_plane_vm_id_start + count.index

  # Hardware specs
  cpu_cores    = var.control_plane_cpu
  memory_mb    = var.control_plane_memory
  disk_size_gb = var.control_plane_disk

  # Proxmox settings
  proxmox_node   = var.proxmox_node
  storage_pool   = var.storage_pool
  template_vm_id = var.talos_template_id
  full_clone     = var.full_clone

  # Network settings
  network_bridge  = var.network_bridge
  network_vlan_id = var.network_vlan_id
  ip_address      = var.control_plane_ips[count.index]
  subnet_mask     = var.subnet_mask
  gateway         = var.gateway
  dns_servers     = var.dns_servers

  # Talos configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.control_plane[count.index].machine_configuration

  # Tags
  common_tags = var.tags
}

# Worker nodes
module "workers" {
  source = "../talos-node"
  count  = var.worker_count

  # Node identity
  node_name = "${var.cluster_name}-worker-${count.index + 1}"
  node_role = "worker"
  vm_id     = var.worker_vm_id_start + count.index

  # Hardware specs
  cpu_cores    = var.worker_cpu
  memory_mb    = var.worker_memory
  disk_size_gb = var.worker_disk

  # Proxmox settings
  proxmox_node   = var.proxmox_node
  storage_pool   = var.storage_pool  # Single storage pool for all nodes
  template_vm_id = var.talos_template_id
  full_clone     = var.full_clone

  # Network settings
  network_bridge  = var.network_bridge
  network_vlan_id = var.network_vlan_id
  ip_address      = var.worker_ips != null ? var.worker_ips[count.index] : ""
  subnet_mask     = var.subnet_mask
  gateway         = var.gateway
  dns_servers     = var.dns_servers

  # Talos configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.worker[count.index].machine_configuration

  # Tags
  common_tags = var.tags
}

# Bootstrap the cluster
resource "talos_machine_bootstrap" "cluster" {
  depends_on = [module.control_plane]

  node                 = var.control_plane_ips[0]
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

# Get kubeconfig
resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [talos_machine_bootstrap.cluster]

  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = var.control_plane_ips[0]
}