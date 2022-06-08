terraform {
  required_version = ">= 1.1.0"

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      # version = "2.9.3"
    }
  }
}

resource "proxmox_vm_qemu" "virtual_machines" {
  name        = var.hostname
  vmid        = var.vmid
  ciuser      = var.username
  target_node = var.target_node
  clone       = var.vm_template
  agent       = 1
  os_type     = var.os_type
  cores       = var.cpu_cores
  sockets     = var.cpu_sockets
  cpu         = "host"
  memory      = var.memory
  scsihw      = var.scsihw
  onboot      = true
  disk {
    size        = var.hdd_size
    type        = var.hdd_type
    storage     = var.storage
    mbps_rd     = var.mbps_rd
    mbps_wr     = var.mbps_wr
    mbps_rd_max = var.mbps_rd_max
    mbps_wr_max = var.mbps_wr_max
    iothread    = var.iothread
  }

  network {
    model  = var.net_model
    bridge = var.net_bridge
    mtu    = var.mtu
    rate   = var.rate
    macaddr =  var.macaddr != "0" ? var.macaddr : null # Conditionally set MAC Address if provided
    # tag    = var.vlan_tag
  }

  # Not sure exactly what this is for. something about 
  # ignoring network changes during the life of the VM.
  lifecycle {
    ignore_changes = [
      # network,
      sshkeys
    ]
  }
  # Cloud-init config
  ipconfig0  = "ip=${var.ip_address}/${var.netmask_cidr},gw=${var.gateway}"
  nameserver = var.nameserver
  desc       = <<EOF
# Pi-Hole
Template: ${var.vm_template}
- Name: ${var.hostname}
- IP: ${var.ip_address}
- CPUs: ${var.cpu_cores}
- Sockets: ${var.cpu_sockets}
- Memory: ${var.memory}
- Disk: ${var.hdd_size}
EOF
}
