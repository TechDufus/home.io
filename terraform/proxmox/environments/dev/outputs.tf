# Development Environment Outputs
# Information about the deployed homelab cluster

output "cluster_info" {
  description = "Complete cluster information"
  value = {
    cluster_name     = var.cluster_name
    environment      = var.environment
    talos_version    = var.talos_version
    control_plane_ip = var.control_plane_ip
    worker_count     = var.worker_nodes.count
  }
}

output "control_plane" {
  description = "Control plane node information"
  value = {
    name       = module.control_plane.node_name
    ip_address = module.control_plane.ip_address
    vm_id      = module.control_plane.node_id
  }
}

output "worker_nodes" {
  description = "Worker node information"
  value = [
    for node in module.worker_nodes : {
      name       = node.node_name
      ip_address = node.ip_address
      vm_id      = node.node_id
    }
  ]
}

output "cluster_endpoints" {
  description = "Cluster access endpoints"
  value = {
    kubernetes_api = "https://${var.control_plane_ip}:6443"
    talos_api      = "${var.control_plane_ip}:50000"
  }
}

output "template_info" {
  description = "Template information"
  value       = module.talos_template.template_info
}

output "next_steps" {
  description = "Commands to access your cluster"
  value = {
    kubectl_context = "kubectl config use-context ${var.cluster_name}"
    talos_context   = "talosctl config context ${var.cluster_name}"
    cluster_health  = "talosctl -n ${var.control_plane_ip} health"
    node_status     = "kubectl get nodes"

    usage_notes = [
      "Kubeconfig and talosconfig have been automatically merged into your local configs",
      "Use 'kubectl config use-context ${var.cluster_name}' to switch to this cluster",
      "Use 'talosctl config context ${var.cluster_name}' to manage Talos nodes",
      "Check cluster health with 'talosctl -n ${var.control_plane_ip} health'"
    ]
  }
}