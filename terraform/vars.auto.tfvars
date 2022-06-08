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
    macaddr      = "56:C4:11:75:6A:32"
  },
  "pm-flux-cumulus-1" = {
    hostname     = "pm-flux-cumulus-1"
    vmid         = "111"
    ip_address   = "10.0.0.11"
    macaddr      = "CA:EE:FE:09:0E:28"
  },
  "pm-flux-cumulus-2" = {
    hostname     = "pm-flux-cumulus-2"
    vmid         = "112"
    ip_address   = "10.0.0.12"
    macaddr      = "22:EF:8E:47:5B:D8"
  },
  "pm-flux-cumulus-3" = {
    hostname     = "pm-flux-cumulus-3"
    vmid         = "113"
    ip_address   = "10.0.0.13"
    macaddr      = "4E:43:52:63:9E:6D"
  },
  "pm-flux-cumulus-4" = {
    hostname     = "pm-flux-cumulus-4"
    vmid         = "114"
    ip_address   = "10.0.0.14"
    macaddr      = "3A:3F:83:BB:DB:04"
  }
}

pihole = {
  "pihole-primary" = {
    hostname     = "pihole-primary"
    vmid         = "105"
    ip_address   = "10.0.0.5"
    macaddr      = "66:2A:D1:74:0A:F2"
  },
  "pihole-secondary" = {
    hostname     = "pihole-secondary"
    vmid         = "106"
    ip_address   = "10.0.0.6"
    macaddr      = "EA:D8:C9:FD:FA:AD"
  }
}

container-host = {
  "container-host" = {
    hostname     = "container-host"
    vmid         = "107"
    ip_address   = "10.0.0.7"
    macaddr      = "06:74:60:C0:37:F6"
  }
}
