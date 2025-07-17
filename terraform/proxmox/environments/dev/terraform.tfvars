
# Required: Your Proxmox node name
proxmox_node         = "proxmox"
talos_template_vm_id = 9200
talos_version        = "1.7.6"

cluster_name        = "homelab-dev"
control_plane_ip    = "10.0.20.20"
control_plane_vm_id = 300
worker_vm_id_start  = 310


# Hardware Configuration
control_plane_nodes = {
  cpu     = 2    # CPU cores for control plane
  memory  = 2048 # Memory in MB (2GB)
  disk_gb = 20   # Disk size in GB
}

worker_nodes = {
  count   = 1    # Number of worker nodes
  cpu     = 2    # CPU cores per worker
  memory  = 2048 # Memory in MB (12GB)
  disk_gb = 20   # Disk size in GB
}


# That's it! Everything else has sensible defaults.
# The cluster will be created with:
# - Name: homelab-dev
# - 1 control plane (4 CPU, 8GB RAM, 80GB disk)
# - 2 workers (4 CPU, 12GB RAM, 100GB disk each)
# - Network: 10.0.20.0/24, gateway 10.0.20.1
# - DNS: 10.0.0.99, 1.1.1.1
# - Flannel CNI
# - VM IDs: Control plane 200, Workers 210-211

# Optional overrides (uncomment as needed):
# cluster_name = "my-cluster"
# worker_nodes = { count = 3, cpu = 8, memory = 16384, disk_gb = 200 }
# gateway = "10.0.20.254"
# dns_servers = ["8.8.8.8", "8.8.4.4"]
# network_vlan_id = 100
# storage_pool = "fast-ssd"
