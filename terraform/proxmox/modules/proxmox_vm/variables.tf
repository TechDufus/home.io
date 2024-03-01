variable "hostname" {
  description = "Hostname of the VM."
  type        = string
}

variable "username" {
  description = "Username of the VM."
  type        = string
  default     = "torque"
}

variable "nameserver" {
  description = "Nameserver of the VM."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address of the VM."
  type        = string
}

variable "searchdomain" {
  description = "Search domain of the VM."
  type        = string
  default     = "home.io"
}

variable "qemu_os" {
  description = "OS of the VM."
  type        = string
  default     = "ubuntu"
}

variable "os_type" {
  description = "OS type of the VM."
  type        = string
  default     = "cloud-init"
}

variable "netmask_cidr" {
  description = "Netmask CIDR of the VM."
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway of the VM."
  type        = string

}

variable "vlan_tag" {
  description = "VLAN tag of the VM."
  type        = number
  default     = -1 #Not Assigned
}

variable "net_model" {
  description = "Network model of the VM."
  type        = string
  default     = "virtio"
}

variable "mtu" {
  description = "MTU of the VM."
  type        = number
  default     = 0
}

variable "net_bridge" {
  description = "Network bridge of the VM."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox VM to host the VM."
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the VM."
  type        = number
  default     = 1
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the VM."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory of the VM."
  type        = number
  default     = 4096
}

variable "hdd_size" {
  description = "Size of the HDD of the VM."
  type        = number
  default     = 30
}

variable "hdd_type" {
  description = "Type of the HDD of the VM."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the VM."
  type        = string
  default     = "VM-SSD"
}

variable "scsihw" {
  description = "SCSI hardware of the VM."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of the VM."
  type        = string
  default     = "scsi0"
}

variable "vm_template" {
  description = "Template to clone for the VM."
  type        = string
  default     = "ubuntu-server-20.04-template"
}

variable "mbps_rd" {
  description = "Desired read rate of the VM."
  type        = number
  default     = 0
}

variable "mbps_rd_max" {
  description = "Maximum read rate of the VM."
  type        = number
  default     = 0
}

variable "mbps_wr" {
  description = "Desired write rate of the VM."
  type        = number
  default     = 0
}

variable "mbps_wr_max" {
  description = "Maximum write rate of the VM."
  type        = number
  default     = 0
}

variable "ssd" {
  description = "SSD Emulation of the VM."
  type        = number
  default     = 1
}

variable "discard" {
  description = "Discard setting of the VM."
  type        = bool
  default     = false
}

variable "aio" {
  description = "AIO Emulation of the VM."
  type        = string
  default     = "native"
}

# This is set to 1 int above the flux requirements.
# 0 = unlimited / no limit
variable "rate" {
  description = "Mbps rate limit of the VM network speed."
  type        = number
  default     = 0
}

variable "iothread" {
  description = "Enable/Disable I/O thread of the VM drive."
  type        = bool
  default     = false
}

variable "vmid" {
  description = "ID of the VM."
  type        = number
}

variable "ssh_public_keys" {
  description = "Public SSH keys to add to the VM."
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user of the VM."
  type        = string
  default     = "torque"
}

variable "macaddr" {
  description = "MAC address of the VM."
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

variable "notes_title" {
  description = "Title for the notes snippit in the VM Summary"
  type = string
  default = "VM"
}