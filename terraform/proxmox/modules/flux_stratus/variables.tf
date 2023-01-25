variable "hostname" {
  description = "Hostname of the Flux node."
  type        = string
}

variable "username" {
  description = "Username of the Flux node."
  type        = string
  default = "techdufus"
}

variable "nameserver" {
  description = "Nameserver of the Flux node."
  type        = string
}

variable "ip_address" {
  description = "IPv4 address of the Flux node."
  type        = string
}

variable "searchdomain" {
  description = "Search domain of the Flux node."
  type        = string
  default     = "home.io"
}

variable "qemu_os" {
  description = "OS of the Flux node."
  type        = string
  default = "ubuntu"
}

variable "os_type" {
  description = "OS type of the Flux node."
  type        = string
  default = "cloud-init"
}

variable "netmask" {
  description = "Netmask of the Flux Node."
  type = string
  default = "255.255.255.0"
}

variable "netmask_cidr" {
  description = "Netmask CIDR of the Flux node."
  type        = number
  default = 24
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

variable "mtu" {
  description = "MTU of the Flux node."
  type        = number
  default     = 0
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
  default     = 8
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the Flux node."
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory of the Flux node."
  type        = number
  default     = 64000
}

variable "hdd_size" {
  description = "Size of the HDD of the Flux node."
  type        = string
  default     = "890G"
}

variable "hdd_type" {
  description = "Type of the HDD of the Flux node."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the Flux node."
  type        = string
  default     = "VM-SSD"
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
  default     = "ubuntu-server"
}

variable "mbps_rd" {
  description = "Desired read rate of the Flux node."
  type        = number
  default     = 400
}

variable "mbps_rd_max" {
  description = "Maximum read rate of the Flux node."
  type        = number
  default     = 410
}

variable "mbps_wr" {
  description = "Desired write rate of the Flux node."
  type        = number
  default     = 400
}

variable "mbps_wr_max" {
  description = "Maximum write rate of the Flux node."
  type        = number
  default     = 410
}

# This is set to 1 int above the flux requirements.
variable "rate" {
  description = "Mbps rate limit of the Flux node network speed."
  type        = number
  default     = 14
}

variable "iothread" {
  description = "Enable/Disable I/O thread of the Flux node drive."
  type        = number
  default     = 0
}

variable "vmid" {
  description = "ID of the Flux node."
  type        = number
}

variable "ssh_public_keys" {
  description = "Public SSH keys to add to the Flux node."
  type        = string
  default = ""
}

variable "ssh_user" {
  description = "SSH user of the Flux node."
  type        = string
  default     = "techdufus"
}

variable "macaddr" {
  description = "MAC address of the node."
  type        = string
}
