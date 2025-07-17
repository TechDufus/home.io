# Talos Kubernetes Node Module
# Creates Talos Linux nodes for Kubernetes clusters

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
  }
}

# Create Talos node VM from template
resource "proxmox_virtual_environment_vm" "talos_node" {
  name      = var.node_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  # Clone from Talos template
  clone {
    vm_id = var.template_vm_id
    full  = var.full_clone
  }

  # CPU configuration
  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  # Memory configuration  
  memory {
    dedicated = var.memory_mb
  }

  # Main disk (resize from template)
  disk {
    datastore_id = var.storage_pool
    interface    = "scsi0"
    ssd          = true
    discard      = "on"
    size         = var.disk_size_gb
  }

  # Network configuration
  dynamic "network_device" {
    for_each = [1]
    content {
      bridge  = var.network_bridge
      model   = "virtio"
      vlan_id = var.network_vlan_id
    }
  }

  # Operating system type
  operating_system {
    type = "l26"
  }

  # Disable agent wait since Talos doesn't run QEMU guest agent
  agent {
    enabled = false
  }

  # Cloud-init configuration for static IP
  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    # Disable cloud-init user creation (Talos manages this)
    user_account {
      username = "talos"
      password = "disabled"
    }
  }

  # Start VM after creation
  started = true

  # VM protection and boot settings
  protection = var.protection
  on_boot    = var.onboot

  # Talos doesn't run QEMU guest agent, so don't wait for it
  timeout_create   = 300 # 5 minutes max
  timeout_start_vm = 60  # 1 minute max for startup

  # Descriptive notes for Proxmox GUI (markdown format)
  description = <<-EOT
# Homelab ${title(var.environment)} - ${title(var.node_role)} Node

## Cluster Information
- **Cluster**: ${var.cluster_name}
- **Node Role**: ${title(var.node_role)}
- **IP Address**: ${var.ip_address}
- **Environment**: ${var.environment}

## Operating System
**Talos Linux** - Immutable Kubernetes OS
- 🔒 No SSH access (API-only management)
- 🔧 Use `talosctl` for node management
- ☸️ Use `kubectl` for Kubernetes operations

## Management
This VM is managed by Terraform. Do not modify directly in Proxmox.

### Access Commands
```bash
# Node health
talosctl -n ${var.ip_address} health

# Node logs
talosctl -n ${var.ip_address} dmesg

# Kubernetes status
kubectl get node ${var.node_name}
```
EOT

  # Simple tags for identification
  tags = concat(var.common_tags, [
    var.environment,
    var.node_role,
    "talos"
  ])

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Apply Talos machine configuration
resource "talos_machine_configuration_apply" "node" {
  depends_on = [proxmox_virtual_environment_vm.talos_node]

  client_configuration        = var.talos_client_config
  machine_configuration_input = var.machine_config
  node                        = var.ip_address

  config_patches = var.config_patches
}