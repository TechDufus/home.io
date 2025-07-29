# Development Environment Outputs
# Information about the deployed homelab resources

# Cluster outputs are commented out while cluster is disabled
# Uncomment these when you re-enable the cluster in cluster.tf
# 
# output "cluster_info" {
#   description = "Complete cluster information"
#   value = {
#     cluster_name     = var.cluster.name
#     environment      = var.environment
#     talos_version    = var.cluster.talos_version
#     control_plane_ip = var.cluster.control_plane.ip_address
#     worker_count     = var.cluster.worker.count
#   }
# }
# 
# output "control_plane" {
#   description = "Control plane node information"
#   value = module.talos_cluster.control_plane_nodes
# }
# 
# output "worker_nodes" {
#   description = "Worker node information"
#   value = module.talos_cluster.worker_nodes
# }
# 
# output "cluster_endpoints" {
#   description = "Cluster access endpoints"
#   value = {
#     kubernetes_api = module.talos_cluster.cluster_endpoint
#     talos_api      = "${var.cluster.control_plane.ip_address}:50000"
#   }
# }
# 
# output "template_info" {
#   description = "Template information"
#   value       = module.talos_template.template_info
# }
# 
# output "next_steps" {
#   description = "Commands to access your cluster"
#   value = {
#     kubectl_context = "kubectl config use-context ${var.cluster.name}"
#     talos_context   = "talosctl config context ${var.cluster.name}"
#     cluster_health  = "talosctl -n ${var.cluster.control_plane.ip_address} health"
#     node_status     = "kubectl get nodes"
# 
#     usage_notes = [
#       "Kubeconfig and talosconfig have been automatically merged into your local configs",
#       "Use 'kubectl config use-context ${var.cluster.name}' to switch to this cluster",
#       "Use 'talosctl config context ${var.cluster.name}' to manage Talos nodes",
#       "Check cluster health with 'talosctl -n ${var.cluster.control_plane.ip_address} health'"
#     ]
#   }
# }

output "standalone_vms" {
  description = "Standalone VMs information"
  value = {
    for k, v in proxmox_virtual_environment_vm.standalone : k => {
      name       = v.name
      vm_id      = v.vm_id
      ip_address = var.standalone_vms[k].ip_address
      description = v.description
    }
  }
}