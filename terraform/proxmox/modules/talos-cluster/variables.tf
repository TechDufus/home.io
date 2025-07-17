# Talos Cluster Module Variables
# Configuration for creating complete Talos Linux Kubernetes clusters

# Basic Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kubernetes cluster (used for naming and talos cluster name)"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters."
  }
}

variable "base_ip" {
  description = "Starting IP address for the cluster (control plane gets this, workers get +1, +2, etc.)"
  type        = string

  validation {
    condition     = can(cidrhost("${var.base_ip}/32", 0))
    error_message = "Base IP must be a valid IPv4 address."
  }
}

variable "vm_id_start" {
  description = "Starting VM ID for the cluster nodes"
  type        = number

  validation {
    condition     = var.vm_id_start >= 100 && var.vm_id_start <= 999900
    error_message = "VM ID start must be between 100 and 999900 to allow for worker nodes."
  }
}

variable "gateway" {
  description = "Network gateway"
  type        = string

  validation {
    condition     = can(cidrhost("${var.gateway}/32", 0))
    error_message = "Gateway must be a valid IPv4 address."
  }
}

# Worker Configuration
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_count >= 0 && var.worker_count <= 10
    error_message = "Worker count must be between 0 and 10."
  }
}

# Hardware Configuration - Control Plane
variable "control_plane_cores" {
  description = "CPU cores for control plane"
  type        = number
  default     = 4

  validation {
    condition     = var.control_plane_cores >= 2
    error_message = "Control plane must have at least 2 CPU cores."
  }
}

variable "control_plane_memory" {
  description = "Memory in MB for control plane"
  type        = number
  default     = 8192

  validation {
    condition     = var.control_plane_memory >= 2048
    error_message = "Control plane must have at least 2048MB of memory."
  }
}

variable "control_plane_disk" {
  description = "Disk size in GB for control plane"
  type        = number
  default     = 80

  validation {
    condition     = var.control_plane_disk >= 20
    error_message = "Control plane disk must be at least 20GB."
  }
}

# Hardware Configuration - Workers
variable "worker_cores" {
  description = "CPU cores per worker"
  type        = number
  default     = 4

  validation {
    condition     = var.worker_cores >= 2
    error_message = "Worker nodes must have at least 2 CPU cores."
  }
}

variable "worker_memory" {
  description = "Memory in MB per worker"
  type        = number
  default     = 12288

  validation {
    condition     = var.worker_memory >= 2048
    error_message = "Worker nodes must have at least 2048MB of memory."
  }
}

variable "worker_disk" {
  description = "Disk size in GB per worker"
  type        = number
  default     = 100

  validation {
    condition     = var.worker_disk >= 20
    error_message = "Worker disk must be at least 20GB."
  }
}

# Proxmox Configuration
variable "proxmox_node" {
  description = "Proxmox node to deploy on"
  type        = string
  default     = "proxmox"
}

variable "network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN ID (null for no VLAN)"
  type        = number
  default     = null

  validation {
    condition     = var.network_vlan_id == null || try(var.network_vlan_id >= 1 && var.network_vlan_id <= 4094, false)
    error_message = "VLAN ID must be between 1 and 4094 or null."
  }
}

variable "subnet_mask" {
  description = "Subnet mask in CIDR notation"
  type        = number
  default     = 24

  validation {
    condition     = var.subnet_mask >= 8 && var.subnet_mask <= 32
    error_message = "Subnet mask must be between 8 and 32."
  }
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["10.0.0.99", "1.1.1.1", "1.0.0.1"]

  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "At least one DNS server must be specified."
  }
}

# Talos Configuration
variable "talos_version" {
  description = "Talos version to use"
  type        = string
  default     = "1.7.6"
}

# Storage Configuration
variable "storage_pool" {
  description = "Default storage pool for VM disks (can be overridden per node via storage_mapping)"
  type        = string
  default     = "local-lvm"
}

variable "storage_mapping" {
  description = "Map specific nodes to storage pools for JBOD or distributed storage. Keys: 'control_plane', 'worker-1', 'worker-2', etc."
  type        = map(string)
  default     = {}
  # Example: { control_plane = "ssd-pool", worker-1 = "ssd-pool", worker-2 = "hdd-pool-1", worker-3 = "hdd-pool-2" }
}

variable "template_storage_pool" {
  description = "Storage pool for template/ISO storage"
  type        = string
  default     = "local"
}

# Environment and Metadata
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "full_clone" {
  description = "Use full clone instead of linked clone"
  type        = bool
  default     = false
}

variable "onboot" {
  description = "Start VMs on boot"
  type        = bool
  default     = true
}

variable "template_vm_id" {
  description = "VM ID for Talos template (auto-generated if null)"
  type        = number
  default     = null

  validation {
    condition     = var.template_vm_id == null || try(var.template_vm_id >= 100 && var.template_vm_id <= 999999, false)
    error_message = "Template VM ID must be between 100 and 999999 or null."
  }
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["homelab"]
}

# Kubernetes Network Configuration
variable "pod_subnet" {
  description = "Pod network CIDR"
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_subnet, 0))
    error_message = "Pod subnet must be a valid CIDR."
  }
}

variable "service_subnet" {
  description = "Service network CIDR"
  type        = string
  default     = "10.96.0.0/12"

  validation {
    condition     = can(cidrhost(var.service_subnet, 0))
    error_message = "Service subnet must be a valid CIDR."
  }
}