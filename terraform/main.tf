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
  vm_template     = var.vm_template
  target_node     = var.target_node
  storage         = var.storage
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
  vm_template     = var.vm_template
  target_node     = var.target_node
  storage         = var.storage
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
  vm_template     = var.vm_template
  target_node     = var.target_node
  storage         = var.storage
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
  vm_template     = var.vm_template
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
  vm_template     = var.vm_template
  macaddr         = try(each.value.macaddr, "0")
  target_node     = var.target_node
  storage         = var.storage
}
          
#▀████▄     ▄███▀                  ██      ▀███▄   ▀███▀              ▀███          
#  ████    ████                    ██        ███▄    █                  ██          
#  █ ██   ▄█ ██ ▀██▀   ▀██▀▄██▀████████      █ ███   █   ▄██▀██▄   ▄█▀▀███   ▄▄█▀██ 
#  █  ██  █▀ ██   ██   ▄█  ██   ▀▀ ██        █  ▀██▄ █  ██▀   ▀██▄██    ██  ▄█▀   ██
#  █  ██▄█▀  ██    ██ ▄█   ▀█████▄ ██        █   ▀██▄█  ██     █████    ██  ██▀▀▀▀▀▀
#  █  ▀██▀   ██     ███    █▄   ██ ██        █     ███  ██▄   ▄██▀██    ██  ██▄    ▄
#▄███▄ ▀▀  ▄████▄   ▄█     ██████▀ ▀████   ▄███▄    ██   ▀█████▀  ▀████▀███▄ ▀█████▀
#                  ▄█                                                                
#                ██▀                                                                 

module "myst-node" {
  source          = "./modules/myst-node"
  for_each        = var.myst-node
  hostname        = each.value.hostname
  vmid            = each.value.vmid
  nameserver      = var.nameserver
  ip_address      = "${each.value.ip_address}"
  gateway         = var.gateway
  vm_template     = var.vm_template
  macaddr         = try(each.value.macaddr, "0")
  target_node     = var.target_node
  storage         = var.storage
}
