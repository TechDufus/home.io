variable "hostname" {
  description = "Hostname of the k8s node."
  type        = string
}

variable "username" {
  description = "Username of the k8s node."
  type        = string
  default     = "torque"
}

variable "nameserver" {
  description = "Nameserver of the k8s node."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address of the k8s node."
  type        = string
}

variable "searchdomain" {
  description = "Search domain of the k8s node."
  type        = string
  default     = "home.io"
}

variable "qemu_os" {
  description = "OS of the k8s node."
  type        = string
  default     = "ubuntu"
}

variable "os_type" {
  description = "OS type of the k8s node."
  type        = string
  default     = "cloud-init"
}

variable "netmask_cidr" {
  description = "Netmask CIDR of the k8s node."
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway of the k8s node."
  type        = string

}

variable "vlan_tag" {
  description = "VLAN tag of the k8s node."
  type        = number
  default     = -1 #Not Assigned
}

variable "net_model" {
  description = "Network model of the k8s node."
  type        = string
  default     = "virtio"
}

variable "mtu" {
  description = "MTU of the k8s node."
  type        = number
  default     = 0
}

variable "net_bridge" {
  description = "Network bridge of the k8s node."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host the k8s node."
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the k8s node."
  type        = number
  default     = 1
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the k8s node."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory of the k8s node."
  type        = number
  default     = 4096
}

variable "hdd_size" {
  description = "Size of the HDD of the k8s node."
  type        = number
  default     = 30
}

variable "hdd_type" {
  description = "Type of the HDD of the k8s node."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the k8s node."
  type        = string
  default     = "VM-SSD"
}

variable "scsihw" {
  description = "SCSI hardware of the k8s node."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of the k8s node."
  type        = string
  default     = "scsi0"
}

variable "vm_template" {
  description = "Template to clone for the k8s node."
  type        = string
  default     = "ubuntu-server-20.04-template"
}

variable "mbps_rd" {
  description = "Desired read rate of the k8s node."
  type        = number
  default     = 0
}

variable "mbps_rd_max" {
  description = "Maximum read rate of the k8s node."
  type        = number
  default     = 0
}

variable "mbps_wr" {
  description = "Desired write rate of the k8s node."
  type        = number
  default     = 0
}

variable "mbps_wr_max" {
  description = "Maximum write rate of the k8s node."
  type        = number
  default     = 0
}

variable "ssd" {
  description = "SSD Emulation of the k8s node."
  type        = number
  default     = 1
}

variable "discard" {
  description = "Discard of the node."
  type        = bool
  default     = false
}

variable "aio" {
  description = "AIO Emulation of the k8s node."
  type        = string
  default     = "native"
}

# This is set to 1 int above the flux requirements.
# 0 = unlimited / no limit
variable "rate" {
  description = "Mbps rate limit of the k8s node network speed."
  type        = number
  default     = 0
}

variable "iothread" {
  description = "Enable/Disable I/O thread of the k8s node drive."
  type        = bool
  default     = false
}

variable "vmid" {
  description = "ID of the k8s node."
  type        = number
}

variable "ssh_public_keys" {
  description = "Public SSH keys to add to the k8s node."
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user of the k8s node."
  type        = string
  default     = "torque"
}

variable "macaddr" {
  description = "MAC address of the node."
  type        = string
}

variable "agent" {
  description = "QEMU UserAgent for Proxmox"
  type        = number
  default     = 0
}

variable "cloudinit_cdrom_storage" {
  description = "Location of cloudinit cdrom storage"
  type = string
  default = "local-lvm"
}