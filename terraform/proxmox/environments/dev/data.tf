# Data Sources
# External data sources and references

# 1Password data source for Proxmox credentials
data "onepassword_item" "proxmox_credentials" {
  vault = "HomeLab"
  title = "Proxmox"
}

# SSH keys for reference (not needed for Talos)
data "http" "ssh_keys" {
  url = "https://github.com/techdufus.keys"
}
