# Talos Node Module Variables
# Configuration for creating Talos Linux Kubernetes nodes

# Basic Node Configuration
variable "node_name" {
  description = "Base name for the Talos node"
  type        = string
}

variable "node_role" {
  description = "Role of the node: controlplane or worker"
  type        = string

  validation {
    condition     = contains(["controlplane", "worker"], var.node_role)
    error_message = "Node role must be either 'controlplane' or 'worker'."
  }
}

variable "vm_id" {
  description = "Unique VM ID for the node"
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999
    error_message = "VM ID must be between 100 and 999999."
  }
}

variable "proxmox_node" {
  description = "Proxmox node name where the VM will be created"
  type        = string
  default     = "proxmox"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "homelab-k8s"
}

# Template Configuration
variable "template_vm_id" {
  description = "VM ID of the Talos template to clone from"
  type        = number
  default     = 9200
}

variable "full_clone" {
  description = "Whether to perform a full clone (true) or linked clone (false)"
  type        = bool
  default     = false
}

# Hardware Configuration
variable "cpu_cores" {
  description = "Number of CPU cores for the node"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu_cores >= 2 && var.cpu_cores <= 32
    error_message = "CPU cores must be between 2 and 32 for Kubernetes nodes."
  }
}

variable "memory_mb" {
  description = "Memory allocation for the node in MB"
  type        = number
  default     = 4096

  validation {
    condition     = var.memory_mb >= 2048
    error_message = "Kubernetes nodes require at least 2048MB of memory."
  }
}

variable "disk_size_gb" {
  description = "Disk size for the node in GB"
  type        = number
  default     = 40

  validation {
    condition     = var.disk_size_gb >= 20
    error_message = "Kubernetes nodes require at least 20GB disk space."
  }
}

variable "cpu_type" {
  description = "CPU type for the node"
  type        = string
  default     = "x86-64-v2-AES"
}

# Storage Configuration
variable "storage_pool" {
  description = "Storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

# Network Configuration
variable "network_bridge" {
  description = "Network bridge for the node"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN ID for the node network"
  type        = number
  default     = null
}

variable "ip_address" {
  description = "Static IP address for the node (null for DHCP)"
  type        = string
  default     = null
}

variable "subnet_mask" {
  description = "Subnet mask in CIDR notation (e.g., 24)"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Network gateway for the node"
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "List of DNS servers for the node"
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1", "8.8.8.8"]
}

# Talos Configuration
variable "talos_client_config" {
  description = "Talos client configuration for machine management"
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
}

variable "machine_config" {
  description = "Talos machine configuration YAML"
  type        = string
}

variable "config_patches" {
  description = "List of configuration patches to apply"
  type        = list(string)
  default     = []
}

# VM Protection Settings
variable "protection" {
  description = "Enable Proxmox protection to prevent accidental VM deletion"
  type        = bool
  default     = false
}

variable "onboot" {
  description = "Start VM automatically when Proxmox host boots"
  type        = bool
  default     = true
}

# Tagging
variable "common_tags" {
  description = "Common tags for resource organization"
  type        = list(string)
  default = [
    "homelab"
  ]
}