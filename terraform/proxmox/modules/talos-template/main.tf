# Talos Template Module
# Creates Talos Linux templates in Proxmox for Kubernetes nodes

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  # Talos versions and download URLs
  talos_version = var.talos_version

  # Template name includes version for easy identification
  template_name = "talos-${local.talos_version}-template"
}

# Download and decompress Talos image locally first
resource "null_resource" "download_and_decompress_talos" {
  triggers = {
    talos_version = var.talos_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create temp directory if it doesn't exist
      mkdir -p /tmp/talos-images
      
      # Download if not already present
      if [ ! -f "/tmp/talos-images/talos-${var.talos_version}-nocloud-amd64.raw" ]; then
        echo "Downloading Talos ${var.talos_version}..."
        curl -fsSL "https://github.com/siderolabs/talos/releases/download/v${var.talos_version}/nocloud-amd64.raw.xz" \
          -o "/tmp/talos-images/talos-${var.talos_version}-nocloud-amd64.raw.xz"
        
        echo "Decompressing Talos image..."
        if [ -f "/tmp/talos-images/talos-${var.talos_version}-nocloud-amd64.raw.xz" ]; then
          xz -d "/tmp/talos-images/talos-${var.talos_version}-nocloud-amd64.raw.xz"
          echo "Talos ${var.talos_version} ready for upload"
        else
          echo "Failed to download Talos image"
          exit 1
        fi
      else
        echo "Talos ${var.talos_version} already downloaded"
      fi
    EOT
  }
}

# Upload and create template via SSH (more reliable for large files)
resource "null_resource" "create_template" {
  depends_on = [null_resource.download_and_decompress_talos]

  triggers = {
    talos_version = var.talos_version
    template_id   = var.template_vm_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if template already exists first
      if ssh -o StrictHostKeyChecking=no root@${var.proxmox_node} "qm status ${var.template_vm_id} &>/dev/null"; then
        echo "Template ${var.template_vm_id} already exists, skipping creation"
        exit 0
      fi
      
      echo "Creating Talos template ${var.template_vm_id} on Proxmox..."
      echo "Step 1: Uploading Talos image (1.2GB) via rsync..."
      
      # Use rsync for reliable large file transfer with progress
      rsync -avz --progress "/tmp/talos-images/talos-${var.talos_version}-nocloud-amd64.raw" \
        root@${var.proxmox_node}:/tmp/
      
      echo "Step 2: Creating template via SSH..."
      # Create template via SSH
      ssh -o StrictHostKeyChecking=no root@${var.proxmox_node} << 'ENDSSH'
        echo "Creating VM ${var.template_vm_id}..."
        # Create VM with legacy BIOS (simpler, more reliable for Talos)
        qm create ${var.template_vm_id} \
          --name "${local.template_name}" \
          --memory 2048 \
          --cores 2 \
          --net0 virtio,bridge=${var.network_bridge} \
          --cpu ${var.cpu_type} \
          --bios seabios \
          --ostype l26 \
          --agent enabled=0 \
          --numa 1 \
          --machine q35 \
          --description "Talos ${var.talos_version} - Optimized for Kubernetes workloads"
        
        echo "Importing disk (this may take a few minutes)..."
        # Import disk
        qm importdisk ${var.template_vm_id} /tmp/talos-${var.talos_version}-nocloud-amd64.raw ${var.vm_storage_pool}
        
        echo "Configuring VM..."
        # Configure main OS disk (no EFI disk, imported disk is disk-0)
        qm set ${var.template_vm_id} \
          --scsihw virtio-scsi-pci \
          --scsi0 ${var.vm_storage_pool}:vm-${var.template_vm_id}-disk-0,ssd=1,discard=on
        
        # Add serial console and set boot options
        qm set ${var.template_vm_id} --serial0 socket --boot order=scsi0 --bootdisk scsi0
        
        # Performance optimizations for Kubernetes workloads
        qm set ${var.template_vm_id} \
          --args "-cpu host,+aes" \
          --balloon 0
        
        echo "Converting to template..."
        # Convert to template
        qm template ${var.template_vm_id}
        
        # Cleanup temp file
        rm -f /tmp/talos-${var.talos_version}-nocloud-amd64.raw
        
        echo "Template ${var.template_vm_id} created successfully"
ENDSSH
    EOT
  }
}