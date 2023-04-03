#             ▄▄                                                       ▄▄                 
# ▀███▀▀▀███▀███                          ▀███▄   ▀███▀              ▀███                 
#   ██    ▀█  ██                            ███▄    █                  ██                 
#   ██   █    ██ ▀███  ▀███ ▀██▀   ▀██▀     █ ███   █   ▄██▀██▄   ▄█▀▀███   ▄▄█▀██ ▄██▀███
#   ██▀▀██    ██   ██    ██   ▀██ ▄█▀       █  ▀██▄ █  ██▀   ▀██▄██    ██  ▄█▀   ████   ▀▀
#   ██   █    ██   ██    ██     ███         █   ▀██▄█  ██     █████    ██  ██▀▀▀▀▀▀▀█████▄
#   ██        ██   ██    ██   ▄█▀ ██▄       █     ███  ██▄   ▄██▀██    ██  ██▄    ▄█▄   ██
# ▄████▄    ▄████▄ ▀████▀███▄██▄   ▄██▄   ▄███▄    ██   ▀█████▀  ▀████▀███▄ ▀█████▀██████▀

module "flux_cumulus" {
  source          = "./modules/flux_cumulus"
  for_each        = var.cumulus_nodes
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}
module "flux_nimbus" {
  source          = "./modules/flux_nimbus"
  for_each        = var.nimbus_nodes
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}
module "flux_stratus" {
  source          = "./modules/flux_stratus"
  for_each        = var.stratus_nodes
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}

#             ▄▄                                  ▄▄          
# ▀███▀▀▀██▄  ██        ▀████▀  ▀████▀▀         ▀███          
#   ██   ▀██▄             ██      ██              ██          
#   ██   ▄██▀███          ██      ██    ▄██▀██▄   ██   ▄▄█▀██ 
#   ███████   ██          ██████████   ██▀   ▀██  ██  ▄█▀   ██
#   ██        ██   █████  ██      ██   ██     ██  ██  ██▀▀▀▀▀▀
#   ██        ██          ██      ██   ██▄   ▄██  ██  ██▄    ▄
# ▄████▄    ▄████▄      ▄████▄  ▄████▄▄ ▀█████▀ ▄████▄ ▀█████▀

module "pihole" {
  source          = "./modules/pihole"
  for_each        = var.pihole
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = var.storage
}

#                                               ▄▄                                                                        
#   ▄▄█▀▀▀█▄█                     ██            ██                                   ▀████▀  ▀████▀▀                 ██   
# ▄██▀     ▀█                     ██                                                   ██      ██                    ██   
# ██▀       ▀ ▄██▀██▄▀████████▄ ██████ ▄█▀██▄ ▀███ ▀████████▄   ▄▄█▀██▀███▄███         ██      ██    ▄██▀██▄ ▄██▀████████ 
# ██         ██▀   ▀██ ██    ██   ██  ██   ██   ██   ██    ██  ▄█▀   ██ ██▀ ▀▀         ██████████   ██▀   ▀████   ▀▀ ██   
# ██▄        ██     ██ ██    ██   ██   ▄█████   ██   ██    ██  ██▀▀▀▀▀▀ ██      █████  ██      ██   ██     ██▀█████▄ ██   
# ▀██▄     ▄▀██▄   ▄██ ██    ██   ██  ██   ██   ██   ██    ██  ██▄    ▄ ██             ██      ██   ██▄   ▄███▄   ██ ██   
#   ▀▀█████▀  ▀█████▀▄████  ████▄ ▀████████▀██▄████▄████  ████▄ ▀█████▀████▄         ▄████▄  ▄████▄▄ ▀█████▀ ██████▀ ▀████
                                                                                                                        
module "container-host" {
  source          = "./modules/container-host"
  for_each        = var.container-host
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  vm_template     = each.value.vm_template
  macaddr         = try(each.value.macaddr, "0")
  target_node     = var.target_node
  storage         = var.storage
}

module "vpn-host" {
  source          = "./modules/vpn-host"
  for_each        = var.vpn-host
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}


module "casaOS" {
  source          = "./modules/casaOS"
  for_each        = var.casaOS
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template != null ? each.value.vm_template : var.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}

 # ▄▄▄▄▄▄            █                             ▄     ▄               █               ▄             ▄      ▀                 
 # █       ▄▄▄    ▄▄▄█   ▄▄▄    ▄ ▄▄   ▄▄▄         █  █  █  ▄▄▄    ▄ ▄▄  █   ▄   ▄▄▄   ▄▄█▄▄   ▄▄▄   ▄▄█▄▄  ▄▄▄     ▄▄▄   ▄ ▄▄  
 # █▄▄▄▄▄ █▀  █  █▀ ▀█  █▀ ▀█   █▀  ▀ ▀   █        ▀ █▀█ █ █▀ ▀█   █▀  ▀ █ ▄▀   █   ▀    █    ▀   █    █      █    █▀ ▀█  █▀  █ 
 # █      █▀▀▀▀  █   █  █   █   █     ▄▀▀▀█         ██ ██▀ █   █   █     █▀█     ▀▀▀▄    █    ▄▀▀▀█    █      █    █   █  █   █ 
 # █      ▀█▄▄▀  ▀█▄██  ▀█▄█▀   █     ▀▄▄▀█         █   █  ▀█▄█▀   █     █  ▀▄  ▀▄▄▄▀    ▀▄▄  ▀▄▄▀█    ▀▄▄  ▄▄█▄▄  ▀█▄█▀  █   █ 

module "fedora_workstation" {
  source          = "./modules/fedora_workstation"
  for_each        = var.fedora_workstation
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = "fedora-workstation-37-template"
  target_node     = var.target_node
  storage         = each.value.storage
}
 
# ▄     ▄                      █             ▄    ▄                                          
# █  █  █  ▄▄▄   ▄▄▄▄▄  ▄   ▄  █ ▄▄          ██  ██  ▄▄▄   ▄ ▄▄    ▄▄▄    ▄▄▄▄   ▄▄▄    ▄ ▄▄ 
# ▀ █▀█ █ ▀   █     ▄▀  █   █  █▀  █         █ ██ █ ▀   █  █▀  █  ▀   █  █▀ ▀█  █▀  █   █▀  ▀
#  ██ ██▀ ▄▀▀▀█   ▄▀    █   █  █   █         █ ▀▀ █ ▄▀▀▀█  █   █  ▄▀▀▀█  █   █  █▀▀▀▀   █    
#  █   █  ▀▄▄▀█  █▄▄▄▄  ▀▄▄▀█  █   █         █    █ ▀▄▄▀█  █   █  ▀▄▄▀█  ▀█▄▀█  ▀█▄▄▀   █    
#                                                                         ▄  █               
#                                                                          ▀▀                

module "wazuh_manager" {
  source          = "./modules/wazuh_manager"
  for_each        = var.wazuh_manager
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = var.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}
# ░█░█░█░█░█▀▄░█▀▀░█▀▄░█▀█░█▀▀░▀█▀░█▀▀░█▀▀░░░█▄█░█▀█░█▀▀░▀█▀░█▀▀░█▀▄
# ░█▀▄░█░█░█▀▄░█▀▀░█▀▄░█░█░█▀▀░░█░░█▀▀░▀▀█░░░█░█░█▀█░▀▀█░░█░░█▀▀░█▀▄
# ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀▀▀░░░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀
module "k8s_master" {
  source          = "./modules/k8s_master"
  for_each        = var.k8s_master
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}

# ░█░█░█░█░█▀▄░█▀▀░█▀▄░█▀█░█▀▀░▀█▀░█▀▀░█▀▀░░░█▀█░█▀█░█▀▄░█▀▀
# ░█▀▄░█░█░█▀▄░█▀▀░█▀▄░█░█░█▀▀░░█░░█▀▀░▀▀█░░░█░█░█░█░█░█░█▀▀
# ░▀░▀░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀▀▀░░░▀░▀░▀▀▀░▀▀░░▀▀▀
module "k8s_node" {
  source          = "./modules/k8s_node"
  for_each        = var.k8s_nodes
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  macaddr         = try(each.value.macaddr, "0")
  vm_template     = each.value.vm_template
  target_node     = var.target_node
  storage         = each.value.storage
}

