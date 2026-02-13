# Development Environment Variables
# Configuration variables for homelab development environment

# Basic Configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Proxmox Configuration
variable "proxmox_node" {
  description = "Proxmox node name for VM deployment"
  type        = string
  default     = "proxmox"
}

# Storage Configuration
variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "template_storage_pool" {
  description = "Storage pool for ISO images and cloud-init snippets (must support file storage)"
  type        = string
  default     = "VM-SSD-0"
}

# Network Configuration
variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN ID for network isolation"
  type        = number
  default     = null
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.0.20.1"
}

variable "subnet_mask" {
  description = "Subnet mask bits for IP address configuration"
  type        = number
  default     = 24
}

variable "dns_servers" {
  description = "DNS servers for the environment"
  type        = list(string)
  default     = ["10.0.0.99", "1.1.1.1", "1.0.0.1"]
}

# Standalone VMs Configuration
variable "standalone_vms" {
  description = "Configuration for standalone VMs (not part of the cluster)"
  type = map(object({
    vm_id        = number
    cpu          = number
    cpu_sockets  = optional(number, 1)  # Default to 1 socket if not specified
    memory       = number
    disk_gb      = number
    ip_address   = string
    description  = string
    template     = string
    storage_pool = string
    qemu_agent   = optional(bool, true)  # Default to true for Ubuntu VMs
  }))

  default = {}
}
