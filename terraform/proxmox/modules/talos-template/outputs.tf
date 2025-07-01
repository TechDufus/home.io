# Talos Template Module Outputs
# Information about created Talos template

output "template_id" {
  description = "VM ID of the created Talos template"
  value       = var.template_vm_id
}

output "template_name" {
  description = "Name of the created Talos template"
  value       = local.template_name
}

output "talos_version" {
  description = "Talos Linux version used in template"
  value       = local.talos_version
}

output "template_info" {
  description = "Complete template information"
  value = {
    vm_id         = var.template_vm_id
    name          = local.template_name
    talos_version = local.talos_version
    storage_pool  = var.vm_storage_pool
    created_on    = var.proxmox_node
  }
}

output "usage_instructions" {
  description = "Instructions for using this template"
  value = {
    terraform_reference = "template_vm_id = ${var.template_vm_id}"
    
    manual_clone = <<-EOT
      # Clone this template manually:
      qm clone ${var.template_vm_id} <new-vm-id> --name <vm-name>
      qm set <new-vm-id> --memory 4096 --cores 4
      qm resize <new-vm-id> scsi0 +40G
      qm start <new-vm-id>
    EOT
    
    notes = [
      "Talos configures networking via machine config, not cloud-init",
      "No SSH access - management is via Talos API on port 50000",
      "Use talosctl to manage nodes after deployment"
    ]
  }
}