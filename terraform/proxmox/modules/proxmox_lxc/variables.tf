variable "hostname" {
  description = "Hostname of the k8s node."
  type        = string
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

variable "os_type" {
  description = "OS type of the k8s node."
  type        = string
  default     = "ubuntu"
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

variable "memory" {
  description = "Memory of the k8s node."
  type        = number
  default     = 4096
}

variable "rootfs_size" {
  description = "Size of the HDD of the k8s node."
  type        = string
  default     = "8G"
}

variable "storage" {
  description = "Storage of the k8s node."
  type        = string
  default     = "VM-SSD"
}

# Will need to add this into the ansible configuration
variable "os_template" {
  description = "Template to clone for the k8s node."
  type        = string
  default     = "local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz"
}

# This is set to 1 int above the flux requirements.
# 0 = unlimited / no limit
variable "rate" {
  description = "Mbps rate limit of the k8s node network speed."
  type        = number
  default     = 0
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

variable "macaddr" {
  description = "MAC address of the node."
  type        = string
}

variable "cpu_units"{
  description = "CPU weight that the container possesses"
  type        = number
  default     = 1024
}

variable "unprivileged" {
    description = "Boolean that makes the container run as an unprivileged user" 
    type = bool
    default = true
}

variable "net_name" {
    description = "Name of the network - like eth0"
    type = string
    default = "eth0"
  
}

variable "start" {
  description = "Autostart on creation"
  type = bool
  default = true  
}

variable "swap" {
  description = "Swap space available to container"
  type = number
  default = 512

}


variable "mountpoints" {
    description = "List of mount points for container"
    type = list(object({
        key = string
        slot = number
        storage = string
        mp = string
        size = string
    }))
    default = []
}