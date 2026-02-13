# Local Values
# Computed values and common configurations

locals {
  # Simple tags for homelab management
  common_tags = [
    "homelab",
    "dev"
  ]

  # Template VM ID mapping
  template_vm_ids = {
    "ubuntu-24.04-template" = proxmox_virtual_environment_vm.ubuntu_24_template.vm_id
    "ubuntu-22.04-template" = proxmox_virtual_environment_vm.ubuntu_22_template.vm_id
  }
}