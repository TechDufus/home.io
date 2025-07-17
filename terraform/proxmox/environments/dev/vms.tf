# Standalone Virtual Machine Resources
# This file would contain any standalone VMs not part of the Kubernetes cluster

# Currently, there are no standalone VMs in this development environment.
# All compute resources are managed as part of the Talos Kubernetes cluster.

# Example structure for future standalone VMs:
# module "example_vm" {
#   source = "../../modules/proxmox_vm"
#   
#   name         = "example-vm"
#   node_type    = "nimbus"
#   node_count   = 1
#   proxmox_node = var.proxmox_node
#   
#   # Network configuration
#   network_bridge = var.network_bridge
#   vlan_tag       = var.network_vlan_id
#   
#   # Storage configuration
#   storage_pool = var.storage_pool
#   
#   # Tags
#   common_tags = local.common_tags
# }