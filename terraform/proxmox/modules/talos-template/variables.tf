# Talos Template Module Variables
# Configuration for creating Talos Linux templates

variable "proxmox_node" {
  description = "Proxmox node name/IP where template will be created"
  type        = string
  default     = "proxmox"
}

variable "template_vm_id" {
  description = "VM ID for the Talos template"
  type        = number
  default     = 9200
  
  validation {
    condition     = var.template_vm_id >= 9000 && var.template_vm_id <= 9999
    error_message = "Template VM IDs should be between 9000-9999."
  }
}

variable "talos_version" {
  description = "Talos Linux version to download"
  type        = string
  default     = "1.7.6"
}

variable "talos_checksum" {
  description = "SHA256 checksum for Talos image verification (optional)"
  type        = string
  default     = null
}

# Storage Configuration
variable "template_storage_pool" {
  description = "Storage pool for downloaded Talos images"
  type        = string
  default     = "local"
}

variable "vm_storage_pool" {
  description = "Storage pool for template VM disk"
  type        = string
  default     = "local-lvm"
}

variable "template_disk_size" {
  description = "Disk size for template in GB"
  type        = number
  default     = 10
  
  validation {
    condition     = var.template_disk_size >= 10 && var.template_disk_size <= 100
    error_message = "Template disk size must be between 10GB and 100GB."
  }
}

# Network Configuration
variable "network_bridge" {
  description = "Network bridge for template VM"
  type        = string
  default     = "vmbr0"
}

# Hardware Configuration
variable "cpu_type" {
  description = "CPU type for template"
  type        = string
  default     = "x86-64-v2-AES"
  
  validation {
    condition = contains([
      "x86-64-v2-AES",
      "x86-64-v3", 
      "x86-64-v4",
      "host",
      "kvm64"
    ], var.cpu_type)
    error_message = "CPU type must be a valid Proxmox CPU type."
  }
}

variable "bios_type" {
  description = "BIOS type for template (ovmf for UEFI, seabios for legacy)"
  type        = string
  default     = "seabios"
  
  validation {
    condition     = contains(["ovmf", "seabios"], var.bios_type)
    error_message = "BIOS type must be either 'ovmf' (UEFI) or 'seabios' (legacy)."
  }
}

# Tagging
variable "common_tags" {
  description = "Common tags for resource organization"
  type        = list(string)
  default = [
    "homelab",
    "talos"
  ]
}