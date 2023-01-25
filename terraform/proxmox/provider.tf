terraform {
  required_version = ">= 1.1.0"

  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      # version = "2.9.3"
    }
  }
}

variable "proxmox_api_url" {
  type    = string
  default = "https://10.0.0.3:8006/api2/json"
}

variable "pm_user" {
  default   = "terraform-prov@pve"
  sensitive = true
}

variable "pm_password" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = true

  # # Debugging
  # pm_log_enable = true
  # pm_log_file = "terraform-plugin-proxmox.log"
  # pm_debug = true
  # pm_log_levels = {
  #   _default = "debug"
  #   _capturelog = ""
  # }
}
