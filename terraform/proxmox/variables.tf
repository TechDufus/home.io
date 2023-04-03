variable "cumulus_nodes" {
  description = "The number of Cumulus nodes to create and their values"
  type        = map(any)
  default     = {}
}

variable "nimbus_nodes" {
  description = "The number of Nimbus nodes to create and their values"
  type        = map(any)
  default     = {}
}

variable "stratus_nodes" {
  description = "The number of Stratus nodes to create and their values"
  type        = map(any)
  default     = {}
}

variable "k8s_master" {
  description = "Map of k8s master nodes"
  type        = map(any)
  default     = {}
}

variable "k8s_nodes" {
  description = "Map of k8s worker nodes"
  type        = map(any)
  default     = {}
}

variable "fedora_workstation" {
  description = "The number of Fedora Workstations create and their values"
  type        = map(any)
  default     = {}
}

variable "wazuh_manager" {
  description = "The number of wazuh manager VMs to create and their values"
  type        = map(any)
  default     = {}
}

variable "pihole" {
  description = "Provide base pihole config"
  type        = map(any)
  default     = {}
}

variable "container-host" {
  description = "Provide base container-host config"
  type        = map(any)
  default     = {}
}

variable "vpn-host" {
  description = "Provide base vpn-host config"
  type        = map(any)
  default     = {}
}

variable "casaOS" {
  description = "Provide base casaOS config"
  type        = map(any)
  default     = {}
}

variable "gateway" {
  description = "Gateway of the node."
  type        = string
}

variable "nameserver" {
  description = "Nameserver of the node."
  type        = string
}

variable "vlan_tag" {
  description = "VLAN tag of the node."
  type        = number
  default     = 101
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
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the node."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory of the node."
  type        = number
  default     = 7200
}

variable "hdd_type" {
  description = "Type of the HDD of the node."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the node."
  type        = string
  default     = "local-lvm"
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

variable "vm_template" {
  description = "Template to clone for the node."
  type        = string
  default     = "ubuntu-server-20.04-template"
}

