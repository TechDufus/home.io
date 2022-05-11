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
  target_node = var.target_node
  clone       = var.vm_template
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.cpu_cores
  sockets     = var.cpu_sockets
  cpu         = "host"
  memory      = var.memory
  scsihw      = var.scsihw
  bootdisk    = var.bootdisk
  disk {
    slot     = 0
    size     = var.hdd_size
    type     = var.hdd_type
    storage  = var.storage
    iothread = 1
  }

  network {
    model  = var.net_model
    bridge = var.net_bridge
    # tag    = var.vlan_tag
  }

  # Not sure exactly what this is for. something about 
  # ignoring network changes during the life of the VM.
  lifecycle {
    ignore_changes = [
      network
    ]
  }
  # Cloud-init config
  ipconfig0  = "ip=${var.ip_address},gw=${var.gateway}"
  nameserver = var.nameserver
}
