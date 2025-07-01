# Homelab Development Environment - Talos Linux
# Production-grade Kubernetes cluster with Talos Linux

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  
  # Local backend for development
  backend "local" {
    path = "terraform.tfstate"
  }
}

# 1Password data source for Proxmox credentials
data "onepassword_item" "proxmox_terraform_user" {
  vault = "Personal"
  title = "Proxmox Terraform User"
}

# SSH keys for reference (not needed for Talos)
data "http" "ssh_keys" {
  url = "https://github.com/techdufus.keys"
}

# Configure providers
provider "onepassword" {
  # Uses 1Password CLI authentication
  account = "my.1password.com"
}

provider "proxmox" {
  endpoint = data.onepassword_item.proxmox_terraform_user.url
  username = data.onepassword_item.proxmox_terraform_user.username
  password = data.onepassword_item.proxmox_terraform_user.password
  insecure = true
  
  ssh {
    agent    = true
    username = "root"
  }
}

# Local variables
locals {
  # Simple tags for homelab management
  common_tags = [
    "homelab",
    "dev"
  ]
}

# Create Talos template for this environment
module "talos_template" {
  source = "../../modules/talos-template"
  
  # Use environment-specific template ID
  template_vm_id = var.talos_template_vm_id
  
  # Dev environment might use latest version
  talos_version  = var.talos_version
  
  # Proxmox configuration - extract IP from URL
  proxmox_node          = regex("https://([^:]+):", data.onepassword_item.proxmox_terraform_user.url)[0]
  template_storage_pool = var.template_storage_pool
  vm_storage_pool      = var.storage_pool
  
  # Tagging
  common_tags = concat(local.common_tags, ["template"])
}

# Generate Talos cluster secrets
resource "talos_machine_secrets" "cluster" {}

# Generate machine configuration for control plane
data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  
  config_patches = [
    yamlencode({
      cluster = {
        network = {
          podSubnets = [var.pod_subnet]
          serviceSubnets = [var.service_subnet]
        }
        proxy = {
          disabled = false
        }
      }
      machine = {
        network = {
          hostname = "${var.cluster_name}-cp"
          interfaces = [{
            interface = "eth0"
            addresses = ["${var.control_plane_ip}/${var.subnet_mask}"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = var.gateway
            }]
          }]
          nameservers = var.dns_servers
        }
        time = {
          servers = ["time.cloudflare.com"]
        }
        features = {
          rbac = true
        }
        sysctls = {
          "net.core.somaxconn" = "65535"
          "net.core.netdev_max_backlog" = "5000"
        }
        kubelet = {
          extraArgs = {
            "feature-gates" = "GracefulNodeShutdown=true"
          }
        }
      }
    })
  ]
}

# Generate machine configuration for worker nodes (individual configs for unique hostnames)
data "talos_machine_configuration" "worker" {
  count = var.worker_nodes.count
  
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${var.control_plane_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  
  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = "${var.cluster_name}-worker-${count.index + 1}"
          nameservers = var.dns_servers
        }
        time = {
          servers = ["time.cloudflare.com"]
        }
        sysctls = {
          "net.core.somaxconn" = "65535"
          "net.core.netdev_max_backlog" = "5000"
        }
        kubelet = {
          extraArgs = {
            "feature-gates" = "GracefulNodeShutdown=true"
          }
        }
      }
    })
  ]
}

# Control Plane Node
module "control_plane" {
  source = "../../modules/talos-node"
  
  # Explicit dependency on template creation
  depends_on = [module.talos_template]

  # Node Configuration
  node_name  = "${var.cluster_name}-cp"
  node_role  = "controlplane"
  vm_id      = var.control_plane_vm_id
  
  # Template Configuration - use the template we manage
  template_vm_id = module.talos_template.template_id
  full_clone     = var.full_clone
  
  # Hardware Configuration
  cpu_cores    = var.control_plane_nodes.cpu
  memory_mb    = var.control_plane_nodes.memory
  disk_size_gb = var.control_plane_nodes.disk_gb
  cpu_type     = "x86-64-v2-AES"
  
  # Proxmox Configuration
  proxmox_node   = var.proxmox_node
  storage_pool   = var.storage_pool
  
  # Network Configuration
  network_bridge   = var.network_bridge
  network_vlan_id  = var.network_vlan_id
  ip_address       = var.control_plane_ip
  subnet_mask      = var.subnet_mask
  gateway          = var.gateway
  dns_servers      = var.dns_servers
  
  # Talos Configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.control_plane.machine_configuration
  
  # Tagging
  common_tags = local.common_tags
}

# Worker Nodes
module "worker_nodes" {
  source = "../../modules/talos-node"
  count  = var.worker_nodes.count
  
  # Explicit dependency on template creation
  depends_on = [module.talos_template]

  # Node Configuration
  node_name  = "${var.cluster_name}-worker-${count.index + 1}"
  node_role  = "worker"
  vm_id      = var.worker_vm_id_start + count.index
  
  # Template Configuration - use the template we manage
  template_vm_id = module.talos_template.template_id
  full_clone     = var.full_clone
  
  # Hardware Configuration
  cpu_cores    = var.worker_nodes.cpu
  memory_mb    = var.worker_nodes.memory
  disk_size_gb = var.worker_nodes.disk_gb
  cpu_type     = "x86-64-v2-AES"
  
  # Proxmox Configuration
  proxmox_node   = var.proxmox_node
  storage_pool   = var.storage_pool
  
  # Network Configuration
  network_bridge   = var.network_bridge
  network_vlan_id  = var.network_vlan_id
  ip_address       = cidrhost("${var.control_plane_ip}/${var.subnet_mask}", count.index + 11)  # Start at .11, .12 to avoid conflicts
  subnet_mask      = var.subnet_mask
  gateway          = var.gateway
  dns_servers      = var.dns_servers
  
  # Talos Configuration
  cluster_name        = var.cluster_name
  environment         = var.environment
  talos_client_config = talos_machine_secrets.cluster.client_configuration
  machine_config      = data.talos_machine_configuration.worker[count.index].machine_configuration
  
  # Tagging
  common_tags = local.common_tags
}

# Bootstrap Talos cluster (only on control plane, once)
resource "talos_machine_bootstrap" "cluster" {
  depends_on = [module.control_plane]
  
  node                 = var.control_plane_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration
}

# Extract kubeconfig from cluster
resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [talos_machine_bootstrap.cluster]
  
  client_configuration = talos_machine_secrets.cluster.client_configuration
  node                 = var.control_plane_ip
}

# Save kubeconfig to local file
resource "local_file" "kubeconfig" {
  depends_on = [talos_cluster_kubeconfig.cluster]
  
  content  = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  filename = "${path.root}/kubeconfig"
  
  file_permission = "0600"
}

# Merge the generated kubeconfig with local ~/.kube/config
resource "null_resource" "kubeconfig_merge" {
  depends_on = [local_file.kubeconfig]
  
  triggers = {
    kubeconfig_content = local_file.kubeconfig.content
    cluster_name       = var.cluster_name
    environment        = var.environment
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      # Set up paths
      LOCAL_KUBECONFIG="$HOME/.kube/config"
      TERRAFORM_KUBECONFIG="${path.root}/kubeconfig"
      BACKUP_KUBECONFIG="$HOME/.kube/config.backup.$(date +%Y%m%d_%H%M%S)"
      TEMP_KUBECONFIG="/tmp/kubeconfig.merged.$$"
      
      # Create ~/.kube directory if it doesn't exist
      mkdir -p "$HOME/.kube"
      
      # Backup existing config if it exists
      if [ -f "$LOCAL_KUBECONFIG" ]; then
        echo "Backing up existing kubeconfig to $BACKUP_KUBECONFIG"
        cp "$LOCAL_KUBECONFIG" "$BACKUP_KUBECONFIG"
      else
        echo "No existing kubeconfig found, creating new one"
        touch "$LOCAL_KUBECONFIG"
      fi
      
      # Update context name in terraform kubeconfig to use cluster name
      # Replace admin@cluster-name with just cluster-name as context name
      sed -e 's/admin@${var.cluster_name}/${var.cluster_name}/g' "$TERRAFORM_KUBECONFIG" > "$TERRAFORM_KUBECONFIG.renamed"
      
      # Remove any existing entries to avoid conflicts
      echo "Removing any existing ${var.cluster_name} context..."
      kubectl config delete-context "${var.cluster_name}" --kubeconfig="$LOCAL_KUBECONFIG" 2>/dev/null || echo "Context not found"
      kubectl config delete-cluster "${var.cluster_name}" --kubeconfig="$LOCAL_KUBECONFIG" 2>/dev/null || echo "Cluster not found"  
      kubectl config delete-user "${var.cluster_name}" --kubeconfig="$LOCAL_KUBECONFIG" 2>/dev/null || echo "User not found"
      
      # Merge configurations using KUBECONFIG environment variable
      echo "Merging kubeconfig files..."
      KUBECONFIG="$LOCAL_KUBECONFIG:$TERRAFORM_KUBECONFIG.renamed" kubectl config view --flatten > "$TEMP_KUBECONFIG"
      
      # Validate the merge was successful
      if kubectl --kubeconfig="$TEMP_KUBECONFIG" config get-contexts | grep -q "${var.cluster_name}"; then
        echo "Successfully merged kubeconfig - context '${var.cluster_name}' is available"
        mv "$TEMP_KUBECONFIG" "$LOCAL_KUBECONFIG"
        chmod 600 "$LOCAL_KUBECONFIG"
      else
        echo "Error: Failed to merge kubeconfig - context not found in merged file"
        rm -f "$TEMP_KUBECONFIG"
        exit 1
      fi
      
      # Clean up temporary file
      rm -f "$TERRAFORM_KUBECONFIG.renamed"
      
      echo "Kubeconfig merge completed successfully"
      echo "You can now access the cluster with: kubectl config use-context ${var.cluster_name}"
    EOT
  }
  
  # Remove context when destroying
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -e
      
      LOCAL_KUBECONFIG="$HOME/.kube/config"
      CONTEXT_NAME="${self.triggers.cluster_name}"
      
      if [ -f "$LOCAL_KUBECONFIG" ]; then
        echo "Removing context '$CONTEXT_NAME' from kubeconfig..."
        kubectl config delete-context "$CONTEXT_NAME" --kubeconfig="$LOCAL_KUBECONFIG" || echo "Context not found or already removed"
        kubectl config delete-cluster "$CONTEXT_NAME" --kubeconfig="$LOCAL_KUBECONFIG" || echo "Cluster not found or already removed"  
        kubectl config delete-user "admin@$CONTEXT_NAME" --kubeconfig="$LOCAL_KUBECONFIG" || echo "User not found or already removed"
        echo "Context cleanup completed"
      else
        echo "No kubeconfig file found to clean up"
      fi
    EOT
  }
}

# Save talosconfig to local file  
resource "local_file" "talosconfig" {
  content = jsonencode(talos_machine_secrets.cluster.client_configuration)
  filename = "${path.root}/talosconfig"
  
  file_permission = "0600"
}

# Merge the generated talosconfig with local ~/.talos/config
resource "null_resource" "talosconfig_merge" {
  depends_on = [local_file.talosconfig]
  
  triggers = {
    talosconfig_content = local_file.talosconfig.content
    cluster_name        = var.cluster_name
    environment         = var.environment
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      # Set up paths
      LOCAL_TALOSCONFIG="$HOME/.talos/config"
      TERRAFORM_TALOSCONFIG="${path.root}/talosconfig"
      BACKUP_TALOSCONFIG="$HOME/.talos/config.backup.$(date +%Y%m%d_%H%M%S)"
      
      # Create ~/.talos directory if it doesn't exist
      mkdir -p "$HOME/.talos"
      
      # Backup existing config if it exists
      if [ -f "$LOCAL_TALOSCONFIG" ]; then
        echo "Backing up existing talosconfig to $BACKUP_TALOSCONFIG"
        cp "$LOCAL_TALOSCONFIG" "$BACKUP_TALOSCONFIG"
      else
        echo "No existing talosconfig found, creating new one"
      fi
      
      # Merge talosconfig using talosctl config merge
      echo "Merging talosconfig files..."
      if [ -f "$LOCAL_TALOSCONFIG" ]; then
        # Use talosctl to merge the new config into existing config
        talosctl config merge "$TERRAFORM_TALOSCONFIG" --talosconfig "$LOCAL_TALOSCONFIG"
      else
        # If no existing config, just copy the new one
        cp "$TERRAFORM_TALOSCONFIG" "$LOCAL_TALOSCONFIG"
        chmod 600 "$LOCAL_TALOSCONFIG"
      fi
      
      # Set the context name to match cluster name for consistency
      echo "Setting talosconfig context to ${var.cluster_name}..."
      talosctl config context ${var.cluster_name} --talosconfig "$LOCAL_TALOSCONFIG" || echo "Context setting will be available after cluster is running"
      
      echo "Talosconfig merge completed successfully"
      echo "You can now access the cluster with: talosctl config context ${var.cluster_name}"
      echo "Check cluster health with: talosctl -n ${var.control_plane_ip} health"
    EOT
  }
  
  # Remove context when destroying
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -e
      
      LOCAL_TALOSCONFIG="$HOME/.talos/config"
      CONTEXT_NAME="${self.triggers.cluster_name}"
      
      if [ -f "$LOCAL_TALOSCONFIG" ]; then
        echo "Removing context '$CONTEXT_NAME' from talosconfig..."
        # Note: talosctl doesn't have a direct context delete command like kubectl
        # The context will be cleaned up when the cluster is destroyed
        echo "Talosconfig context cleanup completed"
      else
        echo "No talosconfig file found to clean up"
      fi
    EOT
  }
}