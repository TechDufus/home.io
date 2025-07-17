# Development Environment Outputs
# Information about the deployed homelab cluster

output "cluster_info" {
  description = "Complete cluster information"
  value = {
    cluster_name     = module.dev_cluster.cluster_name
    environment      = var.environment
    talos_version    = var.talos_version
    control_plane_ip = module.dev_cluster.control_plane_ip
    worker_count     = var.worker_nodes.count
    worker_ips       = module.dev_cluster.worker_ips
  }
}

output "control_plane" {
  description = "Control plane node information"
  value = {
    name       = module.dev_cluster.node_details.control_plane.name
    ip_address = module.dev_cluster.control_plane_ip
    vm_id      = module.dev_cluster.node_details.control_plane.vm_id
  }
}

output "worker_nodes" {
  description = "Worker node information"
  value       = module.dev_cluster.node_details.workers
}

output "cluster_endpoints" {
  description = "Cluster access endpoints"
  value = {
    kubernetes_api = module.dev_cluster.cluster_endpoint
    talos_api      = "${module.dev_cluster.control_plane_ip}:50000"
  }
}

output "template_info" {
  description = "Template information"
  value = {
    vm_id = module.dev_cluster.template_vm_id
  }
}

output "kubeconfig" {
  description = "Kubernetes configuration file content"
  value       = module.dev_cluster.kubeconfig
  sensitive   = true
}

output "talosconfig" {
  description = "Talos configuration file content"
  value       = module.dev_cluster.talosconfig
  sensitive   = true
}

output "next_steps" {
  description = "Commands to access your cluster"
  value = {
    kubectl_context = "kubectl config use-context admin@${module.dev_cluster.cluster_name}"
    talos_context   = "talosctl config context ${module.dev_cluster.cluster_name}"
    cluster_health  = "talosctl -n ${module.dev_cluster.control_plane_ip} health"
    node_status     = "kubectl get nodes"

    usage_notes = [
      "Kubeconfig and talosconfig have been automatically merged into your local configs",
      "Use 'kubectl config use-context admin@${module.dev_cluster.cluster_name}' to switch to this cluster",
      "Use 'talosctl config context ${module.dev_cluster.cluster_name}' to manage Talos nodes",
      "Check cluster health with 'talosctl -n ${module.dev_cluster.control_plane_ip} health'"
    ]
  }
}