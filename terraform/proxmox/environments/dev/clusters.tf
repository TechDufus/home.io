# Kubernetes Cluster Resources
# Talos Linux Kubernetes cluster configuration for development environment

module "dev_cluster" {
  source = "../../modules/talos-cluster"

  # Basic cluster configuration
  cluster_name = var.cluster_name
  environment  = var.environment
  proxmox_node = var.proxmox_node

  # Network configuration
  base_ip         = var.control_plane_ip
  subnet_mask     = var.subnet_mask
  gateway         = var.gateway
  dns_servers     = var.dns_servers
  network_bridge  = var.network_bridge
  network_vlan_id = var.network_vlan_id

  # Kubernetes networking
  pod_subnet     = var.pod_subnet
  service_subnet = var.service_subnet

  # Hardware configuration
  control_plane_cores  = var.control_plane_nodes.cpu
  control_plane_memory = var.control_plane_nodes.memory
  control_plane_disk   = var.control_plane_nodes.disk_gb

  worker_cores  = var.worker_nodes.cpu
  worker_memory = var.worker_nodes.memory
  worker_disk   = var.worker_nodes.disk_gb
  worker_count  = var.worker_nodes.count

  # Storage
  storage_pool          = var.storage_pool
  template_storage_pool = var.template_storage_pool

  # VM IDs
  vm_id_start    = var.control_plane_vm_id
  template_vm_id = var.talos_template_vm_id

  # Talos version
  talos_version = var.talos_version

  # Tags
  common_tags = concat(var.common_tags, [var.environment])
}

# Create local configuration files
resource "local_file" "talosconfig" {
  content         = module.dev_cluster.talosconfig
  filename        = "${path.module}/talosconfig"
  file_permission = "0600"
}

resource "local_file" "kubeconfig" {
  content         = module.dev_cluster.kubeconfig
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}

# Merge configurations
resource "null_resource" "merge_kubeconfig" {
  depends_on = [local_file.kubeconfig]

  provisioner "local-exec" {
    command = <<-EOT
      export KUBECONFIG="${local_file.kubeconfig.filename}:$HOME/.kube/config"
      kubectl config view --flatten > $HOME/.kube/config.tmp
      mv $HOME/.kube/config.tmp $HOME/.kube/config
      kubectl config use-context admin@${var.cluster_name}
    EOT
  }
}

resource "null_resource" "merge_talosconfig" {
  depends_on = [local_file.talosconfig]

  provisioner "local-exec" {
    command = <<-EOT
      talosctl config merge ${local_file.talosconfig.filename}
    EOT
  }
}