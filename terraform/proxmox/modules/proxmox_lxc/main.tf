terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

resource "proxmox_lxc" "lxc_container" {
  hostname     = var.hostname
  vmid        = var.vmid             
  target_node = var.target_node          
  
  ostype     = var.os_type   
  ostemplate = var.os_template
  cores       = var.cpu_cores                        
  #cpu_    = var.cpu_units           
  memory      = var.memory             
  unprivileged = var.unprivileged
  onboot      = true
  ssh_public_keys = var.ssh_public_keys

  rootfs{
    storage = var.storage
    size = var.rootfs_size
  }

  #This will create a mountpoint for each mountpoint object defined. 
  # 0 Mountpoints means none will be injected and it'll still be fine.
  dynamic "mountpoint" {
    for_each = var.mountpoints

    content {
        key = mountpoint.value.key
        slot = mountpoint.value.slot
        #Could potentially be volume now
        storage = mountpoint.value.storage
        mp = mountpoint.value.mp
        size = mountpoint.value.size        
    }
    
  }

  network {
    name = var.net_name
    bridge  = var.net_bridge
    #mtu     = var.mtu
    #rate    = var.rate
    hwaddr = var.macaddr != "0" ? var.macaddr : null # Conditionally set MAC Address if provided
    tag    = var.vlan_tag
  }

  #clone       = var.vm_template # required a Container to clone

           
  
  


  

  

  # Terraform will ignore these vm object values if / when they change.
  # This might cause terraform to destroy and recreate the VM entirely for some small change.
  # lifecycle {
  #   ignore_changes = [
  #     # network,
  #     sshkeys
  #   ]
  # }
  # Cloud-init config
  # ciuser      = var.username             
  # ipconfig0  = "ip=${var.ip_address}/${var.netmask_cidr},gw=${var.gateway}"
  # nameserver = var.nameserver
  # searchdomain = var.nameserver
  # desc       = <<EOF
# k8s Node
# Template: ${var.vm_template}
# - Name: ${var.hostname}
# - IP: ${var.ip_address}
# - CPUs: ${var.cpu_cores}
# - Sockets: ${var.cpu_sockets}
# - Memory: ${var.memory}
# - Disk: ${var.hdd_size}
# EOF
}