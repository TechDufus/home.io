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
  type = string
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
  pm_api_url = var.proxmox_api_url
  pm_user    = var.proxmox_user
  pm_pass    = var.proxmos_pass
  # pm_api_token_id     = var.proxmox_api_token_id
  # pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = true
}
