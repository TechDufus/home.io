# Provider Configurations
# Configure all providers used in this environment

# 1Password Provider - For secret management
provider "onepassword" {
  # Uses 1Password CLI authentication
  account = "my.1password.com"
}

# Proxmox Provider - For infrastructure provisioning
provider "proxmox" {
  # Extract connection details from 1Password
  endpoint = data.onepassword_item.proxmox_terraform_user.url
  username = data.onepassword_item.proxmox_terraform_user.username
  password = data.onepassword_item.proxmox_terraform_user.password

  # Development settings
  insecure = true # Self-signed certificate
  tmp_dir  = "/tmp"

  ssh {
    agent    = true
    username = "root"
  }
}