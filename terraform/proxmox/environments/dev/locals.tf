# Local Values
# Computed values and common configurations

locals {
  # Simple tags for homelab management
  common_tags = [
    "homelab",
    "dev"
  ]

  # Environment-specific naming
  name_prefix = "${var.environment}-${var.cluster.name}"

  # Computed network values
  network_cidr = "${var.cluster.control_plane.ip_address}/${var.cluster.subnet_mask}"
  
  # Template VM ID mapping
  template_vm_ids = {
    "ubuntu-24.04-template" = proxmox_virtual_environment_vm.ubuntu_24_template.vm_id
    "ubuntu-22.04-template" = proxmox_virtual_environment_vm.ubuntu_22_template.vm_id
  }
}