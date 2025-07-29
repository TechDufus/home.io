# Talos Cluster Module Outputs

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value       = var.control_plane_ips
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = var.worker_ips
}

output "kubeconfig" {
  description = "Kubernetes cluster kubeconfig"
  value       = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = talos_machine_secrets.cluster.client_configuration
  sensitive   = true
}

output "machine_secrets" {
  description = "Talos machine secrets for backup"
  value       = talos_machine_secrets.cluster.machine_secrets
  sensitive   = true
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${var.control_plane_vip != "" ? var.control_plane_vip : var.control_plane_ips[0]}:6443"
}

output "control_plane_nodes" {
  description = "Control plane node details"
  value = {
    for i, node in module.control_plane : 
    node.name => {
      ip     = node.ip_address
      vm_id  = node.vm_id
      mac    = node.mac_address
    }
  }
}

output "worker_nodes" {
  description = "Worker node details"
  value = {
    for i, node in module.workers : 
    node.name => {
      ip     = node.ip_address
      vm_id  = node.vm_id
      mac    = node.mac_address
    }
  }
}