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

# Cluster Configuration
variable "cluster" {
  description = "Talos Kubernetes cluster configuration"
  type = object({
    # Basic cluster identity
    name          = string
    talos_version = string

    # Template configuration
    template_vm_id = number

    # Control plane configuration
    control_plane = object({
      count       = number
      vm_id_start = number
      ip_address  = string
      cpu         = number
      memory      = number
      disk_gb     = number
    })

    # Worker configuration
    worker = object({
      count       = number
      vm_id_start = number
      cpu         = number
      memory      = number
      disk_gb     = number
    })

    # Network configuration
    subnet_mask = number

    # Kubernetes configuration
    cni_plugin     = string
    pod_subnet     = string
    service_subnet = string
    cluster_dns    = string

    # Deployment configuration
    full_clone = bool

    # Storage configuration
    storage_pool = string
  })

  default = {
    name           = "homelab-dev"
    talos_version  = "1.7.6"
    template_vm_id = 9200

    control_plane = {
      count       = 1
      vm_id_start = 300
      ip_address  = "10.0.20.20"
      cpu         = 4
      memory      = 8192
      disk_gb     = 80
    }

    worker = {
      count       = 2
      vm_id_start = 310
      cpu         = 4
      memory      = 12288
      disk_gb     = 100
    }

    subnet_mask = 24

    cni_plugin     = "flannel"
    pod_subnet     = "10.244.0.0/16"
    service_subnet = "10.96.0.0/12"
    cluster_dns    = "10.96.0.10"

    full_clone = false

    storage_pool = "local-lvm"
  }

  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cluster.cni_plugin)
    error_message = "CNI plugin must be flannel, calico, or cilium."
  }

  validation {
    condition     = var.cluster.control_plane.count == 1 || var.cluster.control_plane.count == 3 || var.cluster.control_plane.count == 5
    error_message = "Control plane count must be 1, 3, or 5 for proper etcd quorum."
  }
}

# Standalone VMs Configuration (non-cluster resources)
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
