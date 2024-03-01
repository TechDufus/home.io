#global vars

nameserver    = "10.1.1.1"
gateway       = "10.1.1.1"
searchdomain  = "home.io"
vm_template   = "ubuntu-server-22.04-template"
target_node   = "pve"
storage       = "wdBlue"
username      = "torque"
ssh_public_keys= "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYjmlSd0iE+QyWQReb0kZk2C4s/682CpuT1PNDBP9+YQ8nmTSXrPvse4uptpORNXRdQZC4JK7Xi2WQVzur5dVMxRDgr0RoBv6CuskhIIfe0iKnNk7coldcVPGY+Ff7vJX86c2rzzaq7+C3uRO+TDiWSJ/7DtdTeyV7pHOcoYs49aa/d6vS6uN6i5RW+3X+CmE4t5Mnm4ZCFv1KwsMC0PVjH4FIVmynU7qZ7a2LaTEgiNFgtOlLk2Ccnbu+n2OOHkUysvZR4SejzOAsuckFFMH06c6OIqEa5YKlTQlqqGIJGndeh4+jiS2N1TEWa3ZylJk2kbKCriSgiwOzfeC5or9AlS19w1hmX8a3RG2twdJfovfQUcnxcQ+E3kM2hbGAC2QvqONnI/6mrjT6UK7FM2afFY7wQKQmE6Wi0J6Yb71ue0hzz6ggVHtANFMkXH15bTboScjSQgrTvqRwhSKajV1/Gla51+le8KsjBmq05lG6L0cHtt9acm9qCkyIWpRBhuX1kWlf0V9vEsHcDBZ5sVlWvXMyTTWm2GHJAV5SpRJdRNwRi3ScffMUDLrx8HSAMKnaCp+ejcEsUbIWIQaOQLduGiaVQ+Npt4NkO0l1uvwjPPGKlCEcQOygjhOMVxlKECdU+MsApi/by5p8f0K+6PFkTFGNqKidDK6fmhI97FYVwQ=="

# Use to create privileged containers
# pm_user = "root@pam"


#To create VM's, Agent must be 0. To destroy them, agent must be 1: Github Issue #922
agent         = 0

nimbus_nodes = {
  "pm-flux-nimbus-0" = {
    hostname    = "pm-flux-nimbus-0"
    vmid        = "120"
    ip_address  = "10.0.20.20"
    storage     = "VM-SSD-1"
    macaddr     = "56:C4:11:75:6A:32"
    vm_template = "ubuntu-server-20.04-template"
  },
  "pm-flux-nimbus-1" = {
    hostname    = "pm-flux-nimbus-1"
    vmid        = "121"
    ip_address  = "10.0.20.21"
    storage     = "VM-SSD-2"
    macaddr     = "56:C4:11:75:6A:33"
    vm_template = "ubuntu-server-20.04-template"
  },
  "pm-flux-nimbus-2" = {
    hostname    = "pm-flux-nimbus-2"
    vmid        = "122"
    ip_address  = "10.0.20.22"
    storage     = "VM-SSD-0"
    macaddr     = "56:C4:11:75:6A:34"
    vm_template = "ubuntu-server-22.04-template"
  },
}
cumulus_nodes = {
  # "pm-flux-cumulus-0" = {
  #   hostname   = "pm-flux-cumulus-0"
  #   vmid       = "110"
  #   ip_address = "10.0.20.10"
  #   storage    = "VM-SSD-3"
  #   macaddr    = "56:C4:11:75:6A:11"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "pm-flux-cumulus-1" = {
  #   hostname   = "pm-flux-cumulus-1"
  #   vmid       = "111"
  #   ip_address = "10.0.20.11"
  #   storage    = "VM-SSD-4"
  #   macaddr    = "56:C4:11:75:6A:12"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "pm-flux-cumulus-2" = {
  #   hostname   = "pm-flux-cumulus-2"
  #   vmid       = "112"
  #   ip_address = "10.0.20.12"
  #   storage    = "VM-SSD-0"
  #   macaddr    = "56:C4:11:75:6A:13"
  #   vm_template = "ubuntu-server-20.04-template"
  # },
  # "pm-flux-cumulus-2" = {
  #   hostname   = "pm-flux-cumulus-2"
  #   vmid       = "112"
  #   ip_address = "10.0.20.12"
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
  #   ip_address  = "10.0.20.40"
  #   storage     = "VM-SSD-3"
  #   macaddr     = "56:C4:11:75:6A:40"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-master-1" = {
  #   hostname    = "k8s-master-1"
  #   vmid        = "141"
  #   ip_address  = "10.0.20.41"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:41"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-master-2" = {
  #   hostname    = "k8s-master-2"
  #   vmid        = "142"
  #   ip_address  = "10.0.20.42"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:42"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
}

k8s_nodes = {
  # "test-FluxCore-1" = {
  #   hostname    = "test-FluxCore-1"
  #   vmid        = "150"
  #   ip_address  = "10.0.20.50"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:50"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "test-FluxCore-2" = {
  #   hostname    = "test-FluxCore-2"
  #   vmid        = "151"
  #   ip_address  = "10.0.20.51"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:51"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-1" = {
  #   hostname    = "k8s-node-1"
  #   vmid        = "143"
  #   ip_address  = "10.0.20.43"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:43"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-2" = {
  #   hostname    = "k8s-node-2"
  #   vmid        = "144"
  #   ip_address  = "10.0.20.44"
  #   storage     = "VM-SSD-4"
  #   macaddr     = "56:C4:11:75:6A:44"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "k8s-node-4" = {
  #   hostname    = "k8s-node-4"
  #   vmid        = "146"
  #   ip_address  = "10.0.20.46"
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
  #   ip_address   = "10.0.20.5"
  #   storage      = "VM-SSD"
  #   macaddr      = "66:2A:D1:74:0A:F2"
  # },
  # "pihole-secondary" = {
  #   hostname     = "pihole-secondary"
  #   vmid         = "106"
  #   ip_address   = "10.0.20.6"
  #   storage      = "VM-SSD"
  #   macaddr      = "EA:D8:C9:FD:FA:AD"
  # }
}

container-host = {
  # "container-host" = {
  #   hostname     = "container-host"
  #   vmid         = "149"
  #   ip_address   = "10.0.20.49"
  #   storage      = "VM-SSD-4"
  #   macaddr      = "06:74:60:C0:37:49"
  #   vm_template = "ubuntu-server-22.04-template"
  # },
  # "dev-box" = {
  #   hostname     = "dev-box"
  #   vmid         = "150"
  #   ip_address   = "10.0.20.50"
  #   storage      = "VM-SSD-4"
  #   macaddr      = "06:74:60:C0:37:50"
  #   vm_template = "ubuntu-server-20.04-template"
  # }
}

vpn-host = {
  # "vpn-host" = {
  #   hostname   = "vpn-host"
  #   vmid       = "118"
  #   ip_address = "10.0.20.18"
  #   vm_template = "ubuntu-server-22.04-template"
  #   storage    = "VM-SSD-0"
  # },
}


casaOS = {
  # "casaOS" = {
  #   hostname    = "casaOS"
  #   vmid        = "119"
  #   ip_address  = "10.0.20.19"
  #   storage     = "VM-SSD-0"
  #   macaddr     = "06:77:60:C0:37:F9"
  #   vm_template = "ubuntu-server-22.04-template"
  # }
}

fileserver = {
  "fileserver" = {
    hostname    = "FileServer"
    vmid        = "111"
    ip_address  = "10.1.1.11/24"
    # rootfs_size = 8G # Using default
    storage     = "wdBlue"
    # macaddr     = "" #Let it set and then save it
    os_type     = "debian"

    # local:vztmpl prior to the template name is critical
    os_template = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    #cpu       = 4
    memory      = 2048
    swap        = 512
    unprivileged= false #Default #Requires root to run
    cpu_cores    = 4

    mountpoints = [
      {
        key = "1"
        slot = 1
        storage = "wdBlue"
        mp = "/mnt/share_1"
        size = "100G"
      },
      {
        key = "2"
        slot = 2
        storage = "wdBlue"
        mp = "/mnt/share_2"
        size = "50G"
      }      
    ]
  }
}

# Example Container with rootfs and 2 mounted drives defined.
lxc_cumulus_nodes = {
  "lxc-cumulus0" = {
    hostname    = "lxc-cumulus0"
    vmid        = "110"
    ip_address  = "10.0.20.10/24"
    # rootfs_size = 8G # Using default
    storage = "VM-SSD-0"
    cpu_cores = 4
    # macaddr     = "" #Let it set and then save it
    os_type     = "debian"

    # local:vztmpl prior to the template name is critical, Default Proxmox storage location
    os_template = "local:vztmpl/ubuntu-20.04-standard_20.04-1_amd64.tar.gz"
    unprivileged = true #Default

    mountpoints = [
      {
        key = "1"
        slot = 1
        storage = "VM-SSD-0"
        mp = "/home/techdufus"
        size = "222G"
      }
    ]
  }
}
