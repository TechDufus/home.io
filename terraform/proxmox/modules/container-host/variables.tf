variable "hostname" {
  description = "hostname for the node"
  type        = string
  default     = "container-host"
}

variable "username" {
  description = "username for the node"
  type        = string
  default     = "techdufus"
}

variable "gateway" {
  description = "Gateway of the node."
  type        = string
  default     = "10.0.0.2"
}

variable "nameserver" {
  description = "Nameserver of the node."
  type        = string
  default     = "1.1.1.1"
}

variable "ip_address" {
  description = "IP address of the node."
  type        = string
}

variable "netmask_cidr" {
  description = "Netmask of the node."
  type        = number
  default     = 24
}

variable "vlan_tag" {
  description = "VLAN tag of the node."
  type        = number
  default     = 101
}

variable "searchdomain" {
  description = "Search domain of the node."
  type        = string
  default     = "home.io"
}

variable "qemu_os" {
  description = "OS of the node."
  type        = string
  default     = "ubuntu"
}

variable "mtu" {
  description = "MTU of the node."
  type        = number
  default     = 0
}

variable "net_model" {
  description = "Network model of the node."
  type        = string
  default     = "virtio"
}

variable "net_bridge" {
  description = "Network bridge of the node."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host the node."
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the node."
  type        = number
  default     = 3
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the node."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory of the node."
  type        = number
  default     = 6144
}

variable "hdd_size" {
  description = "Size of the HDD of the node."
  type        = string
  default     = "30G"
}

variable "hdd_type" {
  description = "Type of the HDD of the node."
  type        = string
  default     = "scsi"
}

variable "os_type" {
  description = "OS type of the node."
  type        = string
  default     = "cloud-init"
}

variable "storage" {
  description = "Storage of the node."
  type        = string
  default     = "VM-SSD"
}

variable "scsihw" {
  description = "SCSI hardware of the node."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of the node."
  type        = string
  default     = "scsi0"
}

variable "mbps_rd" {
  description = "Desired read rate of the node."
  type        = number
  default     = 30
}

variable "mbps_rd_max" {
  description = "Maximum read rate of the node."
  type        = number
  default     = 35
}

variable "mbps_wr" {
  description = "Desired write rate of the node."
  type        = number
  default     = 30
}

variable "mbps_wr_max" {
  description = "Maximum write rate of the node."
  type        = number
  default     = 35
}

variable "rate" {
  description = "Mbps rate limit of the node network speed."
  type        = number
  default     = 10
}

variable "iothread" {
  description = "Enable/Disable I/O thread of the node drive."
  type        = number
  default     = 0
}

variable "vmid" {
  description = "ID of the node."
  type        = number
}

variable "vm_template" {
  description = "Template to clone for the node."
  type        = string
  default     = "ubuntu-server-20.04-template"
}

variable "disk_backup" {
  description = "Enable/Disable disk backup of the node."
  type        = number
  default     = 1
}

variable "macaddr" {
  description = "MAC address of the node."
  type        = string
}
