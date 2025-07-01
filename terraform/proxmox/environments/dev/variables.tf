# Development Environment Variables
# Configuration variables for homelab development Kubernetes cluster

# Basic Configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "homelab-dev"
}

# Proxmox Configuration
variable "proxmox_node" {
  description = "Proxmox node name for VM deployment"
  type        = string
  default     = "proxmox"
}

variable "talos_template_vm_id" {
  description = "VM ID for the Talos Linux template (environment-specific)"
  type        = number
  default     = 9200
}

variable "talos_version" {
  description = "Talos Linux version to use in this environment"
  type        = string
  default     = "1.7.6"
}

# VM ID Configuration
variable "control_plane_vm_id" {
  description = "VM ID for the control plane node"
  type        = number
  default     = 200
}

variable "worker_vm_id_start" {
  description = "Starting VM ID for worker nodes"
  type        = number
  default     = 210
}

# Hardware Configuration
variable "control_plane_nodes" {
  description = "Control plane node configuration"
  type = object({
    cpu     = number
    memory  = number
    disk_gb = number
  })
  default = {
    cpu     = 4
    memory  = 8192
    disk_gb = 80
  }
}

variable "worker_nodes" {
  description = "Worker node configuration"
  type = object({
    count   = number
    cpu     = number
    memory  = number
    disk_gb = number
  })
  default = {
    count   = 2
    cpu     = 4
    memory  = 12288
    disk_gb = 100
  }
}

# Network Configuration
variable "control_plane_ip" {
  description = "Static IP address for control plane"
  type        = string
  default     = "10.0.20.10"
}

variable "subnet_mask" {
  description = "Subnet mask in CIDR notation"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "10.0.20.1"
}

variable "dns_servers" {
  description = "DNS servers for the cluster"
  type        = list(string)
  default     = ["10.0.0.99", "1.1.1.1", "1.0.0.1"]
}

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

# Storage Configuration
variable "storage_pool" {
  description = "Proxmox storage pool for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "template_storage_pool" {
  description = "Storage pool for cloud-init snippets"
  type        = string
  default     = "local"
}

# Deployment Configuration
variable "full_clone" {
  description = "Whether to perform full clone or linked clone"
  type        = bool
  default     = false
}

# Kubernetes Configuration
variable "cni_plugin" {
  description = "CNI plugin to use (flannel, calico, cilium)"
  type        = string
  default     = "flannel"
  
  validation {
    condition     = contains(["flannel", "calico", "cilium"], var.cni_plugin)
    error_message = "CNI plugin must be flannel, calico, or cilium."
  }
}

variable "pod_subnet" {
  description = "Pod subnet CIDR for Kubernetes"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_subnet" {
  description = "Service subnet CIDR for Kubernetes"
  type        = string
  default     = "10.96.0.0/12"
}

variable "cluster_dns" {
  description = "Cluster DNS IP address"
  type        = string
  default     = "10.96.0.10"
}