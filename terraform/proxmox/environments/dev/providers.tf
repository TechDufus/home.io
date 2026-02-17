# Provider Configurations
# All provider setup and authentication

# Configure providers
provider "onepassword" {
  # Service account token (env var) and account are mutually exclusive.
  # Set to null when using OP_SERVICE_ACCOUNT_TOKEN, otherwise use CLI auth.
  account = var.op_account
}

provider "proxmox" {
  endpoint = data.onepassword_item.proxmox_credentials.url
  username = data.onepassword_item.proxmox_credentials.username
  password = data.onepassword_item.proxmox_credentials.password
  insecure = true

  ssh {
    agent    = true
    username = "root"
  }
}

