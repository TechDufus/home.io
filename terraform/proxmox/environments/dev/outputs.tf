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
