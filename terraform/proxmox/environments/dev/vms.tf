# Standalone Virtual Machines
# VMs that are not part of the Kubernetes cluster

# NOTE: The templates are defined in templates.tf

# Cloud-init user data to install QEMU guest agent
resource "proxmox_virtual_environment_file" "cloud_init_qemu_agent" {
  for_each = { for k, v in var.standalone_vms : k => v if v.qemu_agent }
  
  content_type = "snippets"
  datastore_id = var.template_storage_pool
  node_name    = var.proxmox_node
  
  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${var.environment}-${each.key}
    package_update: true
    packages:
      - qemu-guest-agent
    users:
      - name: techdufus
        groups: [adm, sudo]
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiL48RdHXOm+Mo2HboWkrrcUKX2odIg23b/3ondXV5d
          - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEF3Lp695h+PZvBuibn/8eSivIKcDFyR2D0SFhSG4v8
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    EOF
    
    file_name = "cloud-init-qemu-agent-${each.key}.yaml"
  }
}

# Standalone VMs (not part of the cluster) - dynamically created from standalone_vms variable
resource "proxmox_virtual_environment_vm" "standalone" {
  for_each = var.standalone_vms

  name        = "${var.environment}-${each.key}"
  node_name   = var.proxmox_node
  vm_id       = each.value.vm_id
  description = each.value.description
  tags        = ["standalone", each.key, var.environment]

  # Clone from template
  clone {
    vm_id = local.template_vm_ids[each.value.template]
    full  = true
  }

  # Hardware configuration
  cpu {
    cores   = each.value.cpu
    sockets = each.value.cpu_sockets
    type    = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  # Disk configuration
  disk {
    datastore_id = each.value.storage_pool
    size         = each.value.disk_gb
    interface    = "scsi0"
  }

  # Network configuration
  network_device {
    bridge  = var.network_bridge
    vlan_id = var.network_vlan_id
  }

  # Cloud-init configuration
  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }
    
    dns {
      servers = var.dns_servers
    }
    
    user_account {
      username = "techdufus"
      keys     = [trimspace(data.http.ssh_keys.response_body)]
    }
    
    user_data_file_id = each.value.qemu_agent ? proxmox_virtual_environment_file.cloud_init_qemu_agent[each.key].id : null
  }

  # Agent configuration
  agent {
    enabled = each.value.qemu_agent
    trim    = true  # Trim network interface info
  }

  # Boot configuration
  boot_order = ["scsi0"]
  
  # Start on boot
  on_boot = true
  
  # Lifecycle to prevent hanging on creation
  lifecycle {
    ignore_changes = [
      initialization,  # Ignore cloud-init changes after initial creation
      agent,          # Can be enabled later if needed
    ]
  }
}