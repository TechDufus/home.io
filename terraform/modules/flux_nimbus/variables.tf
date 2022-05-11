variable "hostname" {
  description = "Hostname of the Flux node."
  type        = string
}

variable "nameserver" {
  description = "Nameserver of the Flux node."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address of the Flux node."
  type        = string
}

variable "gateway" {
  description = "Gateway of the Flux node."
  type        = string
}

variable "vlan_tag" {
  description = "VLAN tag of the Flux node."
  type        = number
  default     = 111
}

variable "net_model" {
  description = "Network model of the Flux node."
  type        = string
  default     = "virtio"
}

variable "net_bridge" {
  description = "Network bridge of the Flux node."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host the Flux node."
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the Flux node."
  type        = number
  default     = 4
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the Flux node."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory of the Flux node."
  type        = number
  default     = 32000
}

variable "hdd_size" {
  description = "Size of the HDD of the Flux node."
  type        = string
  default     = "440GB"
}

variable "hdd_type" {
  description = "Type of the HDD of the Flux node."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the Flux node."
  type        = string
  default     = "local-lvm"
}

variable "scsihw" {
  description = "SCSI hardware of the Flux node."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of the Flux node."
  type        = string
  default     = "scsi0"
}

variable "vm_template" {
  description = "Template to clone for the Flux node."
  type        = string
  default     = "ubuntu-22.04-server-flux"
}

variable "vmid" {
  description = "ID of the Flux node."
  type        = number
}
