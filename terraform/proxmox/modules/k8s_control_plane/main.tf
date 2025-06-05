resource "proxmox_vm_qemu" "k8s_control_plane" {
  name        = var.hostname
  target_node = var.target_node
  vmid        = var.vmid
  
  clone = var.template_name
  
  agent    = 1
  os_type  = "cloud-init"
  cores    = var.cpu_cores
  sockets  = 1
  cpu      = "host"
  memory   = var.memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  
  disk {
    slot    = 0
    size    = var.disk_size
    type    = "scsi"
    storage = var.storage_pool
    iothread = 1
  }
  
  network {
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_tag != -1 ? var.vlan_tag : null
    macaddr = var.macaddr != "" ? var.macaddr : null
  }
  
  lifecycle {
    ignore_changes = [
      network[0].macaddr,
    ]
  }
  
  ipconfig0 = "ip=${var.ip_address}/24,gw=${var.gateway}"
  
  sshkeys = join("\n", var.ssh_keys)
  
  # Cloud-init configuration
  ciuser = "techdufus"
  
  # Custom cloud-init config
  cicustom = "user=local:snippets/k8s-control-plane-${var.hostname}.yml"
  
  # Wait for cloud-init to complete
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
    
    connection {
      type     = "ssh"
      user     = "techdufus"
      host     = var.ip_address
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

# Generate cloud-init configuration
resource "local_file" "cloud_init_user_data" {
  content = templatefile("${path.module}/cloud-init.tftpl", {
    hostname     = var.hostname
    fqdn         = "${var.hostname}.${var.searchdomain}"
    k8s_version  = var.k8s_version
    pod_cidr     = var.pod_cidr
    service_cidr = var.service_cidr
  })
  
  filename = "/var/lib/vz/snippets/k8s-control-plane-${var.hostname}.yml"
  
  provisioner "local-exec" {
    command = "ssh root@${var.target_node} 'mkdir -p /var/lib/vz/snippets'"
  }
}

output "ip_address" {
  value = var.ip_address
}

output "hostname" {
  value = var.hostname
}

output "macaddr" {
  value = proxmox_vm_qemu.k8s_control_plane.network[0].macaddr
}