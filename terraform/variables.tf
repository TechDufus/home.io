variable "flux_gateway" {
  description = "Gateway of the Flux node."
  type = string
}

variable "nameserver" {
  description = "Nameserver of the Flux node."
  type = string
}

variable "vlan_tag" {
  description = "VLAN tag of the Flux node."
  type = number
  default = 101
}

variable "net_model" {
  description = "Network model of the Flux node."
  type = string
  default = "virtio"
}

variable "net_bridge" {
  description = "Network bridge of the Flux node."
  type = string
  default = "vmbr0"
}

variable "target_node" {
  description = "Target ProxMox node to host the Flux node."
  type = string
  default = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores of the Flux node."
  type = number
  default = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets of the Flux node."
  type = number
  default = 1
}

variable "memory" {
  description = "Memory of the Flux node."
  type = number
  default = 7200
}

variable "hdd_size" {
  description = "Size of the HDD of the Flux node."
  type = string
  default = "230GB"
}

variable "hdd_type" {
  description = "Type of the HDD of the Flux node."
  type = string
  default = "scsi"
}

variable "storage" {
  description = "Storage of the Flux node."
  type = string
  default = "local-lvm"
}

variable "scsihw" {
  description = "SCSI hardware of the Flux node."
  type = string
  default = "virtio-scsi-pci"
}

variable "bootdisk" {
  description = "Boot disk of the Flux node."
  type = string
  default = "scsi0"
}

variable "vm_template" {
  description = "Template to clone for the Flux node."
  type = string
  default = "ubuntu-22.04-server-flux"
}

variable "flux_cumulus_count" {
  description = "Number of Cumulus nodes to create."
  type = number
}

variable "flux_cumulus_ip_address_prefix" {
  description = "IPv4 address prefix for the Cumulus nodes."
  type = string
}

variable "flux_nimbus_count" {
  description = "Number of Nimbus nodes to create."
  type = number
}

variable "flux_nimbus_ip_address_prefix" {
  description = "IPv4 address prefix for the Nimbus nodes."
  type = string
}

variable "flux_stratus_count" {
  description = "Number of Stratus nodes to create."
  type = number
}

variable "flux_stratus_ip_address_prefix" {
  description = "IPv4 address prefix for the Stratus nodes."
  type = string
}

variable "proxmox_api_url" {
  type    = string
  default = "https://proxmox.home.io:8006/api2/json"
}

variable "pm_user" {
  type      = string
  sensitive = true
}

variable "pm_password" {
  type      = string
  sensitive = true
}

locals {
  # tflint-ignore: terraform_unused_declarations
  validate_total_node_count = ((var.flux_cumulus_count + var.flux_nimbus_count + var.flux_stratus_count) > 8) ? tobool("The maximum amount of hosted flux nodes is currently '8' and cannot be exceeded.") : true
}