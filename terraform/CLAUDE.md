# Terraform

Provisions Proxmox VE virtual machines using the `bpg/proxmox` provider.

## Structure

```
proxmox/
├── modules/
│   ├── proxmox_vm/    # VM provisioning
│   └── proxmox_lxc/   # LXC containers
├── environments/
│   └── dev/           # Main environment
│       ├── vms.tf
│       ├── providers.tf
│       └── terraform.tfvars
└── scripts/
```

## Commands

```bash
cd terraform/proxmox/environments/dev
terraform init
terraform plan
terraform apply
```

## Adding a VM

VMs use the `standalone_vms` pattern in `environments/dev/vms.tf`:
1. Add VM definition (CPU, memory, disk, IP, cloud-init template)
2. `terraform plan` → `terraform apply`
3. After first apply, pin MAC address in tfvars

## Credentials

- `creds.auto.tfvars` (gitignored) for Proxmox API access
- 1Password CLI for credential lookup: `op signin`, verify with `op vault list`

## Hidden Context

### MAC Address Regeneration
Terraform regenerates MAC addresses on VM updates, breaking DHCP leases. Always pin MAC addresses in tfvars after initial creation.

## Debugging

### State Issues
- "resource already exists" → `terraform state list` to inspect, `terraform import` if needed

### Auth Failures
- `op signin` and verify with `op vault list`

## Style

- Files: lowercase with underscores
- Comments: explain "why" not "what"
- Provider: `bpg/proxmox`
