# home.io

Collection of automation scripts to deploy and manage my internal home lab environment.

## Ansible

I'm currently using Ansible to deploy some of my servers, including the following:

- Dashy
![image](https://user-images.githubusercontent.com/46715299/173632525-8db0d4f4-6bc7-452c-9aa1-e0d6109b5e50.png)


- Portainer
![image](https://user-images.githubusercontent.com/46715299/172434420-46bbac21-37c7-4da6-85d3-4d447f524c8b.png)

- Home Assistant
- Minecraft Server
- Glances endpoints
- Pi-hole(s)
  - Deploy both the primary and secondary pi-hole / DNS servers.
- ProxMox Config
- [Flux Nodes](https://runonflux.io/)

## Terraform

Terraform is used to provision infrastructure across multiple platforms:

### Proxmox VE
Located in `terraform/proxmox/`, this manages:
- **Virtual Machines**: Ubuntu-based VMs for various services
- **Kubernetes Clusters**: Talos Linux-based Kubernetes clusters
- **Templates**: Automated OS template creation

The Proxmox infrastructure uses an environment-based structure:
- `terraform/proxmox/environments/dev/` - Development environment
- `terraform/proxmox/modules/` - Reusable Terraform modules

See [terraform/proxmox/environments/dev/terraform.tfvars](terraform/proxmox/environments/dev/terraform.tfvars) for configuration examples.

#### State Management with 1Password
The `terraform/proxmox/scripts/tfstate` script provides secure Terraform state management using 1Password:

**Features:**
- **Secure Storage**: Store Terraform state files in 1Password vaults
- **Multi-Environment**: Support for different environments (dev, staging, prod)
- **Smart Sync**: Automatically sync based on timestamps
- **State History**: Keep backups of state changes

**Usage:**
```bash
# Check sync status for current environment
./terraform/proxmox/scripts/tfstate status

# Push local state to 1Password
./terraform/proxmox/scripts/tfstate push dev

# Pull state from 1Password
./terraform/proxmox/scripts/tfstate pull dev

# Smart sync (auto push/pull based on timestamps)
./terraform/proxmox/scripts/tfstate sync dev

# List all states in 1Password
./terraform/proxmox/scripts/tfstate list
```

**Commands:**
- `push` - Upload local state to 1Password
- `pull` / `restore` - Download state from 1Password
- `sync` - Smart sync based on which is newer
- `status` - Check sync status
- `list` - Show all Terraform states in vault
- `delete` - Remove state from 1Password
- `envs` - List available environments

The script automatically detects available environments from the `terraform/proxmox/environments/` directory structure.

### Harvester HCI
Located in `terraform/harvester/` for hyper-converged infrastructure management.

## More to come:

- PFSense or OPNSense
- Networking Solution (With DHCP) - Currently handled by gateway.
- Internal CI/CD (Jenkins?)

I'm also planning to deploy some of my other servers / services via `k8s` in the future. To be decided.

## Why have this home lab configuration public?

Well... I'd like to think that I have something to contribute to the community, and if my scripts are useful, I'd like to share them. Obviously this reveals a little bit of how I'm configuring my home lab and network, but I would like to still share as much as I can.


## Quirks

### #1 Regenerating MAC Address
When deploying a VM with Terraform, or when Terraform needs to make a change to a VM (nameserver, IP, or anything to make VM reboot, etc), ProxMox will auto-assign a new MAC address to the VM. The behavior of this breaks default SSH authentication without specifying `-o StrictHostKeyChecking=no` manually, which I'd like to avoid.

Example of what happens when terraform regenerates a MAC address:
![image](https://user-images.githubusercontent.com/46715299/172637211-000b6223-0f86-4242-9dcc-6dbb0c73789a.png)

### Solution to #1: Regenerating MAC Address
**Note**: This issue primarily affected the legacy telmate/proxmox provider. The newer bpg/proxmox provider (used in `terraform/proxmox/environments/`) handles MAC addresses more reliably.

For the legacy setup, when deploying a `NEW` VM, you do not need to specify the MAC Address (`macaddr` variable) in your variable map. BUT once the VM is deployed and a MAC exists for that VM, it's a good idea to add that MAC Address to your variable map so Terraform keeps this MAC address and doesn't regenerate it.

Example from the new environment-based structure in `terraform/proxmox/environments/dev/terraform.tfvars`:

`Initial Terraform Deployment`

```hcl
standalone_vms = {
  n8n-server = {
    vm_id       = 151
    cpu         = 4
    memory      = 4096
    disk_gb     = 50
    ip_address  = "10.0.20.151"
    template    = "ubuntu-24.04-template"
    storage_pool = "VM-SSD-1"
  }
}
```

`Post-Terraform Deployment` (if using legacy modules that require MAC preservation)

```hcl
standalone_vms = {
  n8n-server = {
    vm_id       = 151
    cpu         = 4
    memory      = 4096
    disk_gb     = 50
    ip_address  = "10.0.20.151"
    template    = "ubuntu-24.04-template"
    storage_pool = "VM-SSD-1"
    macaddr     = "06:74:60:C0:37:F6"  # Added after initial deployment
  }
}
```

**NOTE**: The newer bpg/proxmox provider handles MAC addresses better, so this workaround may not be necessary for new deployments.
