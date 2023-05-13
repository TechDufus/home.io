#global vars
nameserver  = "10.0.0.99"
gateway     = "10.0.0.1"
vm_template = "ubuntu-server-20.04-template"
target_node = "proxmox"

nimbus_nodes = {
  "pm-flux-nimbus-0" = {
    hostname    = "pm-flux-nimbus-0"
    vmid        = "120"
    ip_address  = "10.0.0.20"
    storage     = "VM-SSD-1"
    macaddr     = "56:C4:11:75:6A:32"
    vm_template = "ubuntu-server-20.04-template"
  },
  "pm-flux-nimbus-1" = {
    hostname    = "pm-flux-nimbus-1"
    vmid        = "121"
    ip_address  = "10.0.0.21"
    storage     = "VM-SSD-2"
    macaddr     = "56:C4:11:75:6A:33"
    vm_template = "ubuntu-server-20.04-template"
  },
}
cumulus_nodes = {
  "pm-flux-cumulus-0" = {
    hostname   = "pm-flux-cumulus-0"
    vmid       = "110"
    ip_address = "10.0.0.10"
    storage    = "VM-SSD-3"
    macaddr    = "56:C4:11:75:6A:11"
    vm_template = "ubuntu-server-20.04-template"
  },
  "pm-flux-cumulus-1" = {
    hostname   = "pm-flux-cumulus-1"
    vmid       = "111"
    ip_address = "10.0.0.11"
    storage    = "VM-SSD-4"
    macaddr    = "56:C4:11:75:6A:12"
    vm_template = "ubuntu-server-20.04-template"
  },
  # "pm-flux-cumulus-2" = {
  #   hostname   = "pm-flux-cumulus-2"
  #   vmid       = "112"
  #   ip_address = "10.0.0.12"
  #   storage    = "VM-SSD-2"
  #   macaddr    = "56:C4:11:75:6A:13"
  #   vm_template = "ubuntu-server-20.04-template"
  # },
  # "pm-flux-cumulus-3" = {
  #   hostname   = "pm-flux-cumulus-3"
  #   vmid       = "113"
  #   ip_address = "192.168.1.13"
  #   storage    = "VM-SSD-0"
  #   macaddr    = "56:C4:11:75:6A:14"
  #   vm_template = "ubuntu-server-20.04-template"
  # },
  # "pm-flux-cumulus-4" = {
  #   hostname   = "pm-flux-cumulus-4"
  #   vmid       = "114"
  #   ip_address = "192.168.1.14"
  #   storage    = "VM-SSD-2"
  #   macaddr    = "56:C4:11:75:6A:15"
    # vm_template = "ubuntu-server-20.04-template"
  # },
}

k8s_master = {
  # "k8s-master-0" = {
  #   hostname    = "k8s-master-0"
  #   vmid        = "140"
  #   ip_address  = "10.0.0.40"
  #   storage     = "VM-SSD-3"
  #   macaddr     = "56:C4:11:75:6A:40"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
}

k8s_nodes = {
  # "k8s-node-1" = {
  #   hostname    = "k8s-node-1"
  #   vmid        = "143"
  #   ip_address  = "10.0.0.43"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:43"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-2" = {
  #   hostname    = "k8s-node-2"
  #   vmid        = "144"
  #   ip_address  = "10.0.0.44"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:44"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-3" = {
  #   hostname    = "k8s-node-3"
  #   vmid        = "145"
  #   ip_address  = "10.0.0.45"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:45"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-4" = {
  #   hostname    = "k8s-node-4"
  #   vmid        = "146"
  #   ip_address  = "10.0.0.46"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:46"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
}

fedora_workstation = {
  # "fedora_workstation" = {
  #     hostname   = "fedora workstation"
  #     vmid       = "420"
  #     ip_address = "1923.168.1.42"
  #     storage    = "vm-ssd-1"
  #     macaddr    = "56:c4:11:75:6a:42"
  # },
}

wazuh_manager = {
  # "wazuh_manager" = {
  #   hostname     = "wazuh-manager"
  #   vmid         = "109"
  #   ip_address   = "192.168.1.9"
  #   storage      = "VM-SSD-0"
  #   macaddr      = "56:C4:11:85:6A:32"
  # },
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
  #   vmid         = "109"
  #   ip_address   = "10.0.0.9"
  #   storage      = "VM-SSD-3"
  #   macaddr      = "06:74:60:C0:37:F6"
  #   vm_template = "ubuntu-server-22.04-template"
  # }
}

vpn-host = {
  # "vpn-host" = {
  #   hostname   = "vpn-host"
  #   vmid       = "118"
  #   ip_address = "192.168.1.18"
  #   storage    = "VM-SSD-0"
  # }
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
