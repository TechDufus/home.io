# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
# ░        ░░   ░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░   ░░░░░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░
# ▒   ▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ▒   ▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
# ▒   ▒▒▒▒▒▒▒   ▒   ▒▒   ▒   ▒▒▒   ▒▒▒▒▒▒▒   ▒   ▒▒   ▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒   ▒▒▒▒▒▒     ▒
# ▓       ▓▓▓   ▓   ▓▓   ▓▓▓  ▓   ▓▓▓▓▓▓▓▓   ▓▓   ▓   ▓▓   ▓▓   ▓▓▓   ▓   ▓▓▓  ▓▓▓   ▓▓   ▓▓▓▓
# ▓   ▓▓▓▓▓▓▓   ▓   ▓▓   ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓  ▓   ▓   ▓▓▓▓   ▓  ▓▓▓   ▓▓         ▓▓▓▓    ▓
# ▓   ▓▓▓▓▓▓▓   ▓   ▓▓   ▓▓  ▓▓   ▓▓▓▓▓▓▓▓   ▓▓▓▓  ▓  ▓▓   ▓▓   ▓▓  ▓▓▓   ▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓
# █   ███████   ███      █   ███   ███████   ██████   ████   ██████   █   ████     ████      █
# ████████████████████████████████████████████████████████████████████████████████████████████

module "flux_cumulus" {
  source = "./modules/flux_cumulus"
  count  = var.flux_cumulus_count

  hostname    = "pm-flux-cumulus-${count.index}"
  vmid        = "11${count.index}"
  nameserver  = var.nameserver
  ip_address  = "${var.flux_cumulus_ip_address_prefix}${count.index}"
  gateway     = var.flux_gateway
  vm_template = var.vm_template
  target_node = var.target_node
  storage     = var.storage
}
module "flux_nimbus" {
  source = "./modules/flux_nimbus"
  count  = var.flux_nimbus_count

  hostname    = "pm-flux-nimbus-${count.index}"
  vmid        = "12${count.index}"
  nameserver  = var.nameserver
  ip_address  = "${var.flux_nimbus_ip_address_prefix}`${count.index}"
  gateway     = var.flux_gateway
  vm_template = var.vm_template
  target_node = var.target_node
  storage     = var.storage
}
module "flux_stratus" {
  source = "./modules/flux_stratus"
  count  = var.flux_stratus_count

  hostname    = "pm-flux-stratus-${count.index}"
  vmid        = "13${count.index}"
  nameserver  = var.nameserver
  ip_address  = "${var.flux_stratus_ip_address_prefix}${count.index}"
  gateway     = var.flux_gateway
  vm_template = var.vm_template
  target_node = var.target_node
  storage     = var.storage
}

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
# ░        ░░   ░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░░   ░░░░░░░░░░░░░░░░░   ░░░░░░░░░░░░░░░░░░░░
# ▒   ▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ▒   ▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
# ▒   ▒▒▒▒▒▒▒   ▒   ▒▒   ▒   ▒▒▒   ▒▒▒▒▒▒▒   ▒   ▒▒   ▒▒▒▒   ▒▒▒▒▒▒▒▒▒▒   ▒▒▒▒▒   ▒▒▒▒▒▒     ▒
# ▓       ▓▓▓   ▓   ▓▓   ▓▓▓  ▓   ▓▓▓▓▓▓▓▓   ▓▓   ▓   ▓▓   ▓▓   ▓▓▓   ▓   ▓▓▓  ▓▓▓   ▓▓   ▓▓▓▓
# ▓   ▓▓▓▓▓▓▓   ▓   ▓▓   ▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓   ▓▓▓  ▓   ▓   ▓▓▓▓   ▓  ▓▓▓   ▓▓         ▓▓▓▓    ▓
# ▓   ▓▓▓▓▓▓▓   ▓   ▓▓   ▓▓  ▓▓   ▓▓▓▓▓▓▓▓   ▓▓▓▓  ▓  ▓▓   ▓▓   ▓▓  ▓▓▓   ▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓
# █   ███████   ███      █   ███   ███████   ██████   ████   ██████   █   ████     ████      █
# ████████████████████████████████████████████████████████████████████████████████████████████


