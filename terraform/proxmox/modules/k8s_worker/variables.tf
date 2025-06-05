variable "hostname" {
  description = "Hostname for the worker node"
  type        = string
}

variable "vmid" {
  description = "VM ID for Proxmox"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to deploy on"
  type        = string
  default     = "pve"
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "disk_size" {
  description = "Disk size"
  type        = string
  default     = "100G"
}

variable "storage_pool" {
  description = "Storage pool for the VM disk"
  type        = string
  default     = "local-zfs"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag for the network interface"
  type        = number
  default     = -1
}

variable "ip_address" {
  description = "IP address for the node"
  type        = string
}

variable "gateway" {
  description = "Network gateway"
  type        = string
}

variable "nameservers" {
  description = "DNS nameservers"
  type        = list(string)
  default     = ["10.0.0.2", "10.0.0.3"]
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
  default     = "home.io"
}

variable "ssh_keys" {
  description = "SSH public keys for authentication"
  type        = list(string)
}

variable "macaddr" {
  description = "MAC address (optional, but recommended after initial deployment)"
  type        = string
  default     = ""
}

variable "template_name" {
  description = "Name of the VM template to clone from"
  type        = string
  default     = "ubuntu-2204-cloud"
}

variable "k8s_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.29.0"
}