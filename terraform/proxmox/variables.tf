variable "cumulus_nodes" {
  description = "The number of Cumulus nodes to create and their values"
  type        = map(any)
  default     = {}
}

variable "cumulus_nodes_test" {
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

variable "lxc_cumulus_nodes" {
  description = "The number of LXC Cumulus nodes to create and their values"
  type = map(any)
  default = {}
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

variable "fileserver" {
  description = "Set of LXC containers for fileserver"
  type        = map(any)
  default     = {}
}

variable "gateway" {
  description = "Gateway of the VM."
  type        = string
}

variable "nameserver" {
  description = "Nameserver of the VM."
  type        = string
}

variable "vlan_tag" {
  description = "VLAN tag of the VM."
  type        = number
  default     = -1
}

variable "net_model" {
  description = "Network model of the VM."
  type        = string
  default     = "virtio"
}

variable "net_bridge" {
  description = "Network bridge of the VM."
  type        = string
  default     = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host the node."
  type        = string
  default     = "pve"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the VM."
  type        = number
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the VM."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory of the VM."
  type        = number
  default     = 7200
}

variable "hdd_type" {
  description = "Type of the HDD of the VM."
  type        = string
  default     = "scsi"
}

variable "storage" {
  description = "Storage of the VM."
  type        = string
  default     = "local-lvm"
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

variable "username" {
  description = "Username of the node"
  type        = string
  default     = "torque"
}

variable "searchdomain" {
  description = "Search domain of the node"  
  type        = string
  default     = "home.io"
}

variable "agent" {
  description = "QEMU UserAgent for Proxmox"
  type        = number
  default     = 0
}

variable "notes_title" {
  description = "Title for the notes snippit in the VM Summary"
  type = string
  default = "VM"
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to the VM"
  type        = string
  default     = ""
}

variable "flux_cumulus_requirements" {
  description   = "Requirements for flux Cumulus node"
  type          = object({
    cpu_cores   = number
    memory      = number
    hdd_size    = number
    mbps_rd     = number
    mbps_rd_max = number
    mbps_wr     = number
    mbps_wr_max = number
    rate        = number
  })
  default = {
    cpu_cores   = 2
    memory      = 7400
    hdd_size    = 230
    mbps_rd     = 180
    mbps_rd_max = 185
    mbps_wr     = 180
    mbps_wr_max = 185
    rate        = 3
  }
}

variable "flux_nimbus_requirements" {
  description   = "Requirements for a flux Nimbus Node"
  type          = object({
    cpu_cores   = number
    memory      = number
    hdd_size    = number
    mbps_rd     = number
    mbps_rd_max = number
    mbps_wr     = number
    mbps_wr_max = number
    rate        = number
  })
  default = {
    cpu_cores   = 4
    memory      = 32000
    hdd_size    = 450
    mbps_rd     = 0
    mbps_rd_max = 0
    mbps_wr     = 0
    mbps_wr_max = 0
    rate        = 6
  }
}

variable "flux_stratus_requirements" {
  description   = "Requirements for a flux Nimbus Node"
  type          = object({
    cpu_cores   = number
    memory      = number
    hdd_size    = number
    mbps_rd     = number
    mbps_rd_max = number
    mbps_wr     = number
    mbps_wr_max = number
    rate        = number
  })
  default = {
    cpu_cores   = 8
    memory      = 64000
    hdd_size    = 890
    mbps_rd     = 400
    mbps_rd_max = 410
    mbps_wr     = 400
    mbps_wr_max = 410
    rate        = 14
  }