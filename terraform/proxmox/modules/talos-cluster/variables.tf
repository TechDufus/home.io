# Talos Cluster Module Variables

# Cluster Identity
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Control Plane Configuration
variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 1
  
  validation {
    condition     = var.control_plane_count == 1 || var.control_plane_count == 3 || var.control_plane_count == 5
    error_message = "Control plane count must be 1, 3, or 5 for proper etcd quorum."
  }
}

variable "control_plane_ips" {
  description = "List of IP addresses for control plane nodes"
  type        = list(string)
}

variable "control_plane_vip" {
  description = "Virtual IP for control plane HA (optional)"
  type        = string
  default     = ""
}

variable "control_plane_vm_id_start" {
  description = "Starting VM ID for control plane nodes"
  type        = number
  default     = 110
}

variable "control_plane_cpu" {
  description = "CPU cores for control plane nodes"
  type        = number
  default     = 4
}

variable "control_plane_memory" {
  description = "Memory (MB) for control plane nodes"
  type        = number
  default     = 8192
}

variable "control_plane_disk" {
  description = "Disk size (GB) for control plane nodes"
  type        = number
  default     = 100
}

# Worker Configuration
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "worker_ips" {
  description = "List of IP addresses for worker nodes (null for DHCP)"
  type        = list(string)
  default     = null
}

variable "worker_vm_id_start" {
  description = "Starting VM ID for worker nodes"
  type        = number
  default     = 120
}

variable "worker_cpu" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Memory (MB) for worker nodes"
  type        = number
  default     = 8192
}

variable "worker_disk" {
  description = "Disk size (GB) for worker nodes"
  type        = number
  default     = 100
}

# Network Configuration
variable "subnet_mask" {
  description = "Subnet mask in CIDR notation (e.g., 24)"
  type        = string
  default     = "24"
}

variable "gateway" {
  description = "Network gateway IP"
  type        = string
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN ID for network segregation"
  type        = number
  default     = -1
}

variable "pod_subnets" {
  description = "Pod network CIDR ranges"
  type        = list(string)
  default     = ["10.244.0.0/16"]
}

variable "service_subnets" {
  description = "Service network CIDR ranges"
  type        = list(string)
  default     = ["10.96.0.0/12"]
}

# Proxmox Configuration
variable "proxmox_node" {
  description = "Proxmox node to create VMs on"
  type        = string
  default     = "proxmox"
}

variable "storage_pool" {
  description = "Storage pool for VM disks (single pool for all nodes)"
  type        = string
  default     = "local-lvm"
}

variable "talos_template_id" {
  description = "VM ID of the Talos template"
  type        = number
}

variable "full_clone" {
  description = "Perform full clone instead of linked clone"
  type        = bool
  default     = false
}

# Advanced Configuration
variable "ntp_servers" {
  description = "NTP servers for time synchronization"
  type        = list(string)
  default     = ["time.cloudflare.com"]
}

variable "disable_kube_proxy" {
  description = "Disable kube-proxy (for CNIs that replace it)"
  type        = bool
  default     = false
}

variable "additional_sysctls" {
  description = "Additional sysctl settings"
  type        = map(string)
  default     = {}
}

variable "kubelet_feature_gates" {
  description = "Kubelet feature gates to enable"
  type        = list(string)
  default     = ["GracefulNodeShutdown=true"]
}

variable "kubelet_extra_args" {
  description = "Additional kubelet arguments"
  type        = map(string)
  default     = {}
}

# Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["talos", "kubernetes"]
}