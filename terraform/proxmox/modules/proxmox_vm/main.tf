terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      # version = "3.0.1-rc1"
    }
  }
}

resource "proxmox_vm_qemu" "virtual_machines" {
  name        = var.hostname
  vmid        = var.vmid             
  target_node = var.target_node          
  clone       = var.vm_template

  # Agent needs to 0 for VM to create, 1 to modify: Issue #922           
  agent       = var.agent           
  os_type     = var.os_type      
  cores       = var.cpu_cores            
  sockets     = var.cpu_sockets            
  cpu         = "host"             
  memory      = var.memory             
  scsihw      = var.scsihw             
  onboot      = true
  sshkeys     = var.ssh_public_keys
  boot        = "order=scsi0;ide3"
  bootdisk    = var.bootdisk
  cloudinit_cdrom_storage = var.cloudinit_cdrom_storage
  
  disks{
    scsi {
      scsi0 {
        disk {
          size                = var.hdd_size
          # type              = var.hdd_type      # deprecated
          storage             = var.storage
          mbps_r_burst        = var.mbps_rd_max 
          mbps_wr_burst       = var.mbps_wr_max 
          mbps_r_concurrent   = var.mbps_rd  
          mbps_wr_concurrent  = var.mbps_wr   
          iothread            = var.iothread
          discard             = var.discard
          # aio         = var.aio
          # ssd         = var.ssd
        }
      }
    }
  }

  network {
    model   = var.net_model
    bridge  = var.net_bridge
    #mtu     = var.mtu
    #rate    = var.rate
    macaddr = var.macaddr != "0" ? var.macaddr : null # Conditionally set MAC Address if provided
    tag    = var.vlan_tag
  }

  # Terraform will ignore these vm object values if / when they change.
  # This might cause terraform to destroy and recreate the VM entirely for some small change.
  lifecycle {
    ignore_changes = [
      # network,
      sshkeys
    ]
  }
  # Cloud-init config
  ciuser      = var.username             
  ipconfig0  = "ip=${var.ip_address}/${var.netmask_cidr},gw=${var.gateway}"
  nameserver = var.nameserver
  searchdomain = var.nameserver
  desc       = <<EOF
# k8s Node
Template: ${var.vm_template}
- Name: ${var.hostname}
- IP: ${var.ip_address}
- CPUs: ${var.cpu_cores}
- Sockets: ${var.cpu_sockets}
- Memory: ${var.memory}
- Disk: ${var.hdd_size}
EOF
}