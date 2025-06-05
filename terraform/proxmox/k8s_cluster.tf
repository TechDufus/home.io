# Kubernetes Cluster Configuration for Proxmox

# Control Plane Nodes
module "k8s_control_plane" {
  source = "./modules/k8s_control_plane"
  
  for_each = var.k8s_control_plane_nodes
  
  hostname       = each.value.hostname
  vmid           = each.value.vmid
  target_node    = try(each.value.target_node, "pve")
  cpu_cores      = try(each.value.cpu_cores, 4)
  memory         = try(each.value.memory, 8192)
  disk_size      = try(each.value.disk_size, "50G")
  storage_pool   = try(each.value.storage_pool, "local-zfs")
  network_bridge = try(each.value.network_bridge, "vmbr0")
  vlan_tag       = try(each.value.vlan_tag, -1)
  ip_address     = each.value.ip_address
  gateway        = var.gateway
  nameservers    = var.nameservers
  searchdomain   = var.searchdomain
  ssh_keys       = var.ssh_keys
  macaddr        = try(each.value.macaddr, "")
  template_name  = var.template_name
  k8s_version    = var.k8s_version
  pod_cidr       = var.pod_cidr
  service_cidr   = var.service_cidr
}

# Worker Nodes
module "k8s_worker" {
  source = "./modules/k8s_worker"
  
  for_each = var.k8s_worker_nodes
  
  hostname       = each.value.hostname
  vmid           = each.value.vmid
  target_node    = try(each.value.target_node, "pve")
  cpu_cores      = try(each.value.cpu_cores, 4)
  memory         = try(each.value.memory, 8192)
  disk_size      = try(each.value.disk_size, "100G")
  storage_pool   = try(each.value.storage_pool, "local-zfs")
  network_bridge = try(each.value.network_bridge, "vmbr0")
  vlan_tag       = try(each.value.vlan_tag, -1)
  ip_address     = each.value.ip_address
  gateway        = var.gateway
  nameservers    = var.nameservers
  searchdomain   = var.searchdomain
  ssh_keys       = var.ssh_keys
  macaddr        = try(each.value.macaddr, "")
  template_name  = var.template_name
  k8s_version    = var.k8s_version
}

# Output cluster information
output "k8s_control_plane_ips" {
  value = {
    for k, v in module.k8s_control_plane : k => {
      hostname = v.hostname
      ip       = v.ip_address
      macaddr  = v.macaddr
    }
  }
}

output "k8s_worker_ips" {
  value = {
    for k, v in module.k8s_worker : k => {
      hostname = v.hostname
      ip       = v.ip_address
      macaddr  = v.macaddr
    }
  }
}