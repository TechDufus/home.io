#global vars
nameserver  = "1.1.1.1 8.8.8.8"
gateway     = "192.168.1.1"
vm_template = "ubuntu-server-20.04-template"
target_node = "proxmox"

cumulus_nodes = {
  "pm-flux-cumulus-0" = {
    hostname   = "pm-flux-cumulus-0"
    vmid       = "110"
    ip_address = "192.168.1.10"
    storage    = "VM-SSD-0"
    macaddr    = "56:C4:11:75:6A:32"
  },
  "pm-flux-cumulus-1" = {
    hostname   = "pm-flux-cumulus-1"
    vmid       = "111"
    ip_address = "192.168.1.11"
    storage    = "VM-SSD-1"
    macaddr    = "CA:EE:FE:09:0E:28"
  },
  "pm-flux-cumulus-2" = {
    hostname   = "pm-flux-cumulus-2"
    vmid       = "112"
    ip_address = "192.168.1.12"
    storage    = "VM-SSD-2"
    macaddr    = "22:EF:8E:47:5B:D8"
  },
  "pm-flux-cumulus-3" = {
    hostname   = "pm-flux-cumulus-3"
    vmid       = "113"
    ip_address = "192.168.1.13"
    storage    = "VM-SSD-0"
    macaddr    = "4E:43:52:63:9E:6D"
  },
  "pm-flux-cumulus-4" = {
    hostname   = "pm-flux-cumulus-4"
    vmid       = "114"
    ip_address = "192.168.1.14"
    storage    = "VM-SSD-3"
    macaddr    = "3A:3F:83:BB:DB:04"
  }
  "pm-flux-cumulus-5" = {
    hostname   = "pm-flux-cumulus-5"
    vmid       = "115"
    ip_address = "192.168.1.15"
    storage    = "VM-SSD-4"
    macaddr    = "1A:44:53:BD:C0:72"
  },
  "pm-flux-cumulus-6" = {
    hostname   = "pm-flux-cumulus-6"
    vmid       = "116"
    ip_address = "192.168.1.16"
    storage    = "VM-SSD-1"
    macaddr    = "1A:44:53:BD:C0:71"
  },
  "pm-flux-cumulus-7" = {
    hostname   = "pm-flux-cumulus-7"
    vmid       = "117"
    ip_address = "192.168.1.17"
    storage    = "VM-SSD-2"
    macaddr    = "1A:44:53:BD:C1:71"
  }
}

pihole = {
  # "pihole-primary" = {
  #   hostname     = "pihole-primary"
  #   vmid         = "105"
  #   ip_address   = "10.0.0.5"
  #   storage      = "VM-SSD"
  #   macaddr      = "66:2A:D1:74:0A:F2"
  # },
  # "pihole-secondary" = {
  #   hostname     = "pihole-secondary"
  #   vmid         = "106"
  #   ip_address   = "10.0.0.6"
  #   storage      = "VM-SSD"
  #   macaddr      = "EA:D8:C9:FD:FA:AD"
  # }
}

container-host = {
  # "container-host" = {
  #   hostname     = "container-host"
  #   vmid         = "107"
  #   ip_address   = "10.0.0.7"
  #   storage      = "VM-SSD"
  #   macaddr      = "06:74:60:C0:37:F6"
  # }
}

vpn-host = {
  "vpn-host" = {
    hostname   = "vpn-host"
    vmid       = "118"
    ip_address = "192.168.1.18"
    storage    = "VM-SSD-0"
  }
}


casaOS = {
  # "casaOS" = {
  #   hostname    = "casaOS"
  #   vmid        = "119"
  #   ip_address  = "192.168.1.19"
  #   storage     = "VM-SSD-0"
  #   macaddr     = "06:77:60:C0:37:F9"
  #   vm_template = "ubuntu-server-22.04-template"
  # }
}
