# Talos Cluster Module Outputs
# Provides essential information about the created cluster

# Basic cluster information
output "cluster_name" {
  description = "The name of the created cluster"
  value       = var.cluster_name
}

output "control_plane_ip" {
  description = "IP address of the control plane"
  value       = local.control_plane_ip
}

output "worker_ips" {
  description = "List of worker node IPs"
  value       = local.worker_ips
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${local.control_plane_ip}:6443"
}

# Authentication and configuration
output "kubeconfig" {
  description = "Generated kubeconfig for cluster access"
  value       = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Generated talosconfig for cluster management"
  value       = jsonencode(talos_machine_secrets.cluster.client_configuration)
  sensitive   = true
}

# VM identification
output "vm_ids" {
  description = "Map of node names to VM IDs"
  value = {
    control_plane = var.vm_id_start
    workers       = [for i in range(var.worker_count) : var.vm_id_start + i + 1]
  }
}

output "machine_secrets" {
  description = "Talos machine secrets for advanced operations"
  value       = talos_machine_secrets.cluster.machine_secrets
  sensitive   = true
}

output "template_vm_id" {
  description = "VM ID of the Talos template"
  value       = local.template_vm_id
}

# Detailed node information
output "node_details" {
  description = "Detailed information about all nodes"
  value = {
    control_plane = {
      name    = "${var.cluster_name}-cp"
      ip      = local.control_plane_ip
      vm_id   = var.vm_id_start
      cores   = var.control_plane_cores
      memory  = var.control_plane_memory
      disk    = var.control_plane_disk
      storage = local.control_plane_storage
    }
    workers = [for i in range(var.worker_count) : {
      name    = "${var.cluster_name}-worker-${i + 1}"
      ip      = local.worker_ips[i]
      vm_id   = var.vm_id_start + i + 1
      cores   = var.worker_cores
      memory  = var.worker_memory
      disk    = var.worker_disk
      storage = local.worker_storage[i]
    }]
  }
}

# Additional useful outputs
output "node_names" {
  description = "List of all node names"
  value = concat(
    ["${var.cluster_name}-cp"],
    [for i in range(var.worker_count) : "${var.cluster_name}-worker-${i + 1}"]
  )
}

output "all_node_ips" {
  description = "List of all node IPs (control plane + workers)"
  value       = concat([local.control_plane_ip], local.worker_ips)
}

output "network_config" {
  description = "Network configuration details"
  value = {
    gateway        = var.gateway
    subnet_mask    = var.subnet_mask
    dns_servers    = var.dns_servers
    pod_subnet     = var.pod_subnet
    service_subnet = var.service_subnet
  }
}

output "storage_mapping" {
  description = "Storage pool assignments for each node"
  value = merge(
    { control_plane = local.control_plane_storage },
    { for i in range(var.worker_count) : "worker-${i + 1}" => local.worker_storage[i] }
  )
}