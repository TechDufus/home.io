# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a home lab Infrastructure as Code (IaC) repository that uses Ansible for configuration management and Terraform for infrastructure provisioning on Proxmox and Harvester hypervisors. The domain is `home.io`.

## Common Development Commands

### Ansible Commands

```bash
# Deploy full ProxMox configuration
ansible-playbook ./playbooks/proxmox.yaml

# Deploy specific service with tags
ansible-playbook ./playbooks/container-host.yaml --tags dashy
ansible-playbook ./playbooks/pihole.yaml --tags secondary

# Deploy common role to all hosts
ansible-playbook ./playbooks/common-role.yaml
```

**Note:** Ansible uses vault encryption for secrets. The vault password file is configured in `ansible.cfg` at `~/.ansible-vault/vault.secret`.

### Terraform Commands

```bash
# From terraform/proxmox/ or terraform/harvester/
terraform init
terraform plan
terraform apply
```

**Note:** Requires a `creds.auto.tfvars` file (not in source control) with sensitive variables like `pm_password`.

## Architecture and Structure

### Directory Layout
- `/ansible/` - Configuration management with Ansible
  - `/playbooks/` - Main playbooks for different services
  - `/roles/` - Reusable Ansible roles
  - `/inventory/` - Host inventories (prod, fluxnodes)
- `/terraform/` - Infrastructure provisioning
  - `/proxmox/` - Proxmox VM/LXC provisioning
  - `/harvester/` - Harvester provisioning (in development)
  - `/modules/` - Reusable Terraform modules
- `/kubernetes/` - K8s configurations with ArgoCD

### Key Services Deployed
- **Infrastructure**: Pi-hole (primary/secondary), Proxmox, VPN
- **Containers**: Portainer, Home Assistant, Dashy, Glances, CasaOS
- **Applications**: Minecraft server
- **Distributed**: Flux cryptocurrency nodes

### Important Configuration Patterns

1. **MAC Address Management**: When Terraform creates/modifies VMs, add the MAC address to `vars.auto.tfvars` to prevent regeneration on subsequent runs.

2. **Ansible Configuration** (`ansible.cfg`):
   - Host key checking disabled
   - YAML output formatting
   - SSH pipelining enabled
   - Vault password file: `~/.ansible-vault/vault.secret`

3. **Network Configuration**:
   - Domain: `home.io`
   - VLAN support configured
   - Custom DNS via Pi-hole
   - Gateway defined in Terraform variables

4. **Security**:
   - Ansible Vault for secrets
   - SSH key-based authentication
   - Terraform credentials in `creds.auto.tfvars` (gitignored)