
# Development Environment Configuration
# Proxmox node configuration
proxmox_node = "proxmox"

# Cluster configuration using the new cluster object
# cluster = {
#   name          = "homelab-dev"
#   talos_version = "1.7.6"
#   template_vm_id = 9200
#
#   control_plane = {
#     count       = 1
#     vm_id_start = 300
#     ip_address  = "10.0.20.20"
#     cpu         = 2
#     memory      = 2048
#     disk_gb     = 20
#   }
#
#   worker = {
#     count       = 1
#     vm_id_start = 310
#     cpu         = 2
#     memory      = 2048
#     disk_gb     = 20
#   }
#
#   subnet_mask = 24
#
#   cni_plugin     = "flannel"
#   pod_subnet     = "10.244.0.0/16"
#   service_subnet = "10.96.0.0/12"
#   cluster_dns    = "10.96.0.10"
#
#   full_clone = false
#   storage_pool = "VM-SSD-0"
# }

# Standalone VMs (not part of the cluster)
standalone_vms = {
  # claude-code = {
  #   vm_id       = 150
  #   cpu         = 4
  #   cpu_sockets = 2
  #   memory      = 8192
  #   disk_gb     = 150
  #   ip_address  = "10.0.20.150"
  #   description = <<-EOF
  #     Claude Code VM for development and testing.
  #     This VM is used for running AI models and development tasks.
  #     Ensure it has sufficient resources for optimal performance.
  #     EOF
  #   template    = "ubuntu-24.04-template"
  #   storage_pool = "VM-SSD-2"
  # },

  n8n-server = {
    vm_id       = 150
    cpu         = 3
    cpu_sockets = 2
    memory      = 8192
    disk_gb     = 50
    ip_address  = "10.0.20.150"
    description = <<-EOF
      n8n workflow automation server.
      This VM runs n8n for workflow automation and integrations.
      Configured with sufficient resources for moderate workloads.
      EOF
    template    = "ubuntu-24.04-template"
    storage_pool = "VM-SSD-1"
  }
}

# Storage configuration
template_storage_pool = "local"  # Use local storage for ISO/template downloads

# Optional overrides (uncomment as needed):
# gateway = "10.0.20.254"
# dns_servers = ["8.8.8.8", "8.8.4.4"]
# network_vlan_id = 100
