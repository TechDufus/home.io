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
  default = "https://proxmox.home.io:8006/api2/json"
}

variable "proxmox_user" {
  type      = string
  sensitive = true
}

variable "proxmox_pass" {
  type      = string
  sensitive = true
}

provider "proxmox" {
  pm_api_url  = var.proxmox_api_url
  pm_user     = var.proxmox_user
  pm_password = var.proxmox_pass
  pm_tls_insecure = true
  # Uncomment the below for debugging.
  # pm_log_enable = true
  # pm_log_file = "terraform-plugin-proxmox.log"
  # pm_debug = true
  # pm_log_levels = {
  #   _default = "debug"
  #   _capturelog = ""
  # }
}
