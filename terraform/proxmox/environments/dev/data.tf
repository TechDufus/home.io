# Data Sources
# External data sources used across the environment

# 1Password data source for Proxmox credentials
data "onepassword_item" "proxmox_terraform_user" {
  vault = "Personal"
  title = "Proxmox Terraform User"
}

# SSH keys for reference (not needed for Talos)
data "http" "ssh_keys" {
  url = "https://github.com/techdufus.keys"
}