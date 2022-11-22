variable "hostname" {
  description = "Hostname of workstation."
  type        = string
}

variable "username" {
  description = "Username of workstation."
  type        = string
  default     = "techdufus"
}

variable "nameserver" {
  description = "Nameserver of workstation."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address of workstation."
  type        = string
}

variable "searchdomain" {
  description = "Search domain of workstation."
  type        = string
  default     = "home.io"
}

variable "qemu_os" {
  description = "OS of workstation."
  type        = string
  default     = "ubuntu"
}

variable "os_type" {
  description = "OS type of workstation."
  type        = string
  default     = "cloud-init"
}

variable "netmask_cidr" {
  description = "Netmask CIDR of workstation."
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway of workstation."
  type        = string

}

variable "vlan_tag" {
  description = "VLAN tag of workstation."
  type        = number
  default     = 111
}

variable "net_model" {
  description = "Network model of workstation."
  type        = string
  default     = "virtio"
}

variable "mtu" {
  description = "MTU of workstation."
  type        = number
  default     = 0
}

variable "net_bridge" {
  description = "Network bridge of workstation."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host workstation."
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of workstation."
  type        = number
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of workstation."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory of workstation."
  type        = number
  default     = 7400
}

variable "hdd_size" {
  description = "Size of the HDD of workstation."
  type        = string
  default     = "50G"
}

variable "hdd_type" {
  description = "Type of the HDD of workstation."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of workstation."
  type        = string
  default     = "VM-SSD"
}

variable "scsihw" {
  description = "SCSI hardware of workstation."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of workstation."
  type        = string
  default     = "scsi0"
}

variable "vm_template" {
  description = "Template to clone for workstation."
  type        = string
  default     = "fedora-workstation-37-template"
}

variable "mbps_rd" {
  description = "Desired read rate of workstation."
  type        = number
  default     = 0
}

variable "mbps_rd_max" {
  description = "Maximum read rate of workstation."
  type        = number
  default     = 0
}

variable "mbps_wr" {
  description = "Desired write rate of workstation."
  type        = number
  default     = 0
}

variable "mbps_wr_max" {
  description = "Maximum write rate of workstation."
  type        = number
  default     = 0
}

variable "ssd" {
  description = "SSD Emulation of workstation."
  type        = number
  default     = 1
}

variable "discard" {
  description = "Discard of the node."
  type        = string
  default     = "on"
}

variable "aio" {
  description = "AIO Emulation of workstation."
  type        = string
  default     = "native"
}

# This is set to 1 int above the flux requirements.
# 0 = unlimited / no limit
variable "rate" {
  description = "Mbps rate limit of workstation network speed."
  type        = number
  default     = 10
}

variable "iothread" {
  description = "Enable/Disable I/O thread of workstation drive."
  type        = number
  default     = 0
}

variable "vmid" {
  description = "ID of workstation."
  type        = number
}

variable "ssh_public_keys" {
  description = "Public SSH keys to add to workstation."
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user of workstation."
  type        = string
  default     = "techdufus"
}

variable "macaddr" {
  description = "MAC address of the node."
  type        = string
}

