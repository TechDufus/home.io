# VM Templates
# Base OS templates for cloning

# Ubuntu 24.04 LTS Template
resource "proxmox_virtual_environment_vm" "ubuntu_24_template" {
  name        = "ubuntu-24.04-template"
  node_name   = var.proxmox_node
  vm_id       = 9000
  description = "Ubuntu 24.04 LTS Template"
  tags        = ["template", "ubuntu", "24.04"]
  
  # Mark as template
  template = true
  
  # Hardware configuration
  cpu {
    cores = 2
    type  = "host"
  }
  
  memory {
    dedicated = 2048
  }
  
  # Boot disk
  disk {
    datastore_id = var.storage_pool  # Use VM storage pool for the disk
    file_id      = proxmox_virtual_environment_download_file.ubuntu_24_04_cloud_image.id
    interface    = "scsi0"
    size         = 20
  }
  
  # Network - will be configured by cloud-init on clone
  network_device {
    bridge = var.network_bridge
  }
  
  # Enable QEMU agent
  agent {
    enabled = true
  }
  
  # Boot order
  boot_order = ["scsi0"]
  
  # Serial console
  serial_device {}
  
  # Cloud-init defaults (will be overridden on clone)
  initialization {
    datastore_id = var.storage_pool
  }
}

# Download Ubuntu 24.04 cloud image
resource "proxmox_virtual_environment_download_file" "ubuntu_24_04_cloud_image" {
  content_type = "iso"
  datastore_id = var.template_storage_pool
  node_name    = var.proxmox_node
  
  url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  file_name = "ubuntu-24.04-cloudimg.img"
  # checksum  = ""  # Optional: Add SHA256 checksum for verification
  # checksum_algorithm = "sha256"
}

# Ubuntu 22.04 LTS Template
resource "proxmox_virtual_environment_vm" "ubuntu_22_template" {
  name        = "ubuntu-22.04-template"
  node_name   = var.proxmox_node
  vm_id       = 9001
  description = "Ubuntu 22.04 LTS Template"
  tags        = ["template", "ubuntu", "22.04"]
  
  # Mark as template
  template = true
  
  # Hardware configuration
  cpu {
    cores = 2
    type  = "host"
  }
  
  memory {
    dedicated = 2048
  }
  
  # Boot disk
  disk {
    datastore_id = var.storage_pool  # Use VM storage pool for the disk
    file_id      = proxmox_virtual_environment_download_file.ubuntu_22_04_cloud_image.id
    interface    = "scsi0"
    size         = 20
  }
  
  # Network - will be configured by cloud-init on clone
  network_device {
    bridge = var.network_bridge
  }
  
  # Enable QEMU agent
  agent {
    enabled = true
  }
  
  # Boot order
  boot_order = ["scsi0"]
  
  # Serial console
  serial_device {}
  
  # Cloud-init defaults (will be overridden on clone)
  initialization {
    datastore_id = var.storage_pool
  }
}

# Download Ubuntu 22.04 cloud image
resource "proxmox_virtual_environment_download_file" "ubuntu_22_04_cloud_image" {
  content_type = "iso"
  datastore_id = var.template_storage_pool
  node_name    = var.proxmox_node
  
  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name = "ubuntu-22.04-cloudimg.img"
  # checksum  = ""  # Optional: Add SHA256 checksum for verification
  # checksum_algorithm = "sha256"
}

# Optional: Debian 12 Template
# resource "proxmox_virtual_environment_vm" "debian_12_template" {
#   name        = "debian-12-template"
#   node_name   = var.proxmox_node
#   vm_id       = 9002
#   description = "Debian 12 (Bookworm) Template"
#   tags        = ["template", "debian", "12"]
#   
#   template = true
#   
#   cpu {
#     cores = 2
#     type  = "host"
#   }
#   
#   memory {
#     dedicated = 2048
#   }
#   
#   disk {
#     datastore_id = var.template_storage_pool
#     file_id      = proxmox_virtual_environment_download_file.debian_12_cloud_image.id
#     interface    = "scsi0"
#     size         = 20
#   }
#   
#   network_device {
#     bridge = var.network_bridge
#   }
#   
#   disk {
#     datastore_id = var.template_storage_pool
#     interface    = "ide2"
#     file_format  = "raw"
#     size         = 4
#   }
#   
#   agent {
#     enabled = true
#   }
#   
#   boot_order = ["scsi0"]
#   serial_device {}
#   
#   initialization {
#     datastore_id = var.template_storage_pool
#   }
# }