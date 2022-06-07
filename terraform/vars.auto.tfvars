#global vars
nameserver = "10.0.0.5 10.0.0.6"
gateway = "10.0.0.2"
vm_template = "ubuntu-server-20.04-template"
target_node = "proxmox"
storage = "VM-SSD"

cumulus_nodes = {
  "pm-flux-cumulus-0" = {
    hostname     = "pm-flux-cumulus-0"
    vmid         = "110"
    ip_address   = "10.0.0.10"
  },
  "pm-flux-cumulus-1" = {
    hostname     = "pm-flux-cumulus-1"
    vmid         = "111"
    ip_address   = "10.0.0.11"
  },
  "pm-flux-cumulus-2" = {
    hostname     = "pm-flux-cumulus-2"
    vmid         = "112"
    ip_address   = "10.0.0.12"
  },
  "pm-flux-cumulus-3" = {
    hostname     = "pm-flux-cumulus-3"
    vmid         = "113"
    ip_address   = "10.0.0.13"
  },
  "pm-flux-cumulus-4" = {
    hostname     = "pm-flux-cumulus-4"
    vmid         = "114"
    ip_address   = "10.0.0.14"
  }
}

pihole = {
  "pihole-primary" = {
    hostname     = "pihole-primary"
    vmid         = "105"
    ip_address   = "10.0.0.5"
  },
  "pihole-secondary" = {
    hostname     = "pihole-secondary"
    vmid         = "106"
    ip_address   = "10.0.0.6"
  }
}

container-host = {
  "container-host" = {
    hostname     = "container-host"
    vmid         = "107"
    ip_address   = "10.0.0.7"
  }
}
