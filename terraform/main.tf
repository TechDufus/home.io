resource "proxmox_vm_qemu" "demo-1" {
  name        = "demo-1"
  desc        = "Demo VM"
  vmid        = "401"
  target_node = "proxmox"

  agent = 1

  cores   = 1
  sockets = 1
  cpu     = "host"
  memory  = 512

  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disk {
    storage = "local_lvm"
    type    = "virtuo"
    size    = "5GB"
  }

  os_type    = "cloud_init"
  ipconfig0  = "ip=192.168.0.20/24,gw=192.168.0.1"
  nameserver = "192.168.0.5,192.168.0.6"
}
