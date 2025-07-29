# Talos Node Module Outputs
# Information about created Talos nodes

output "vm_id" {
  description = "Proxmox VM ID of the node"
  value       = var.vm_id
}

output "name" {
  description = "Name of the node"
  value       = var.node_name
}

output "node_name" {
  description = "Full name of the created node"
  value       = proxmox_virtual_environment_vm.talos_node.name
}

output "ip_addresses" {
  description = "IP addresses assigned to the node"
  value       = proxmox_virtual_environment_vm.talos_node.ipv4_addresses
}

output "ip_address" {
  description = "Primary IP address of the node"
  value       = try(proxmox_virtual_environment_vm.talos_node.ipv4_addresses[0][0], var.ip_address != null ? var.ip_address : "DHCP-assigned")
}

output "node_info" {
  description = "Complete node information"
  value = {
    vm_id        = proxmox_virtual_environment_vm.talos_node.id
    name         = proxmox_virtual_environment_vm.talos_node.name
    ip_address   = try(proxmox_virtual_environment_vm.talos_node.ipv4_addresses[0][0], var.ip_address != null ? var.ip_address : "DHCP-assigned")
    role         = var.node_role
    cpu_cores    = var.cpu_cores
    memory_mb    = var.memory_mb
    disk_size_gb = var.disk_size_gb
  }
}

output "talos_node_endpoint" {
  description = "Talos API endpoint for this node"
  value       = try(proxmox_virtual_environment_vm.talos_node.ipv4_addresses[0][0], var.ip_address != null ? var.ip_address : "DHCP-assigned")
}

output "mac_address" {
  description = "MAC address of the primary network interface"
  value       = try(proxmox_virtual_environment_vm.talos_node.network_device[0].mac_address, "unknown")
}