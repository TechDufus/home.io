# Provider Configurations
# All provider setup and authentication

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

