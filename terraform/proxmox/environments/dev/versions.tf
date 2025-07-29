# Terraform and Provider Version Requirements

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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}