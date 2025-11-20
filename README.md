# home.io

<div align="center">

**Modern Home Lab Infrastructure as Code**

[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)](https://www.ansible.com/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white)](https://www.proxmox.com/)
[![Talos](https://img.shields.io/badge/Talos-FF6C2C?style=for-the-badge&logo=talos&logoColor=white)](https://www.talos.dev/)

[![1Password](https://img.shields.io/badge/1Password-0094F5?style=for-the-badge&logo=1password&logoColor=white)](https://1password.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![MetalLB](https://img.shields.io/badge/MetalLB-0078D7?style=for-the-badge&logo=kubernetes&logoColor=white)](https://metallb.universe.tf/)
[![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://gateway-api.sigs.k8s.io/)

</div>

---

## Overview

A production-grade home lab implementing modern DevOps practices with Infrastructure as Code, GitOps, and cloud-native technologies. This project manages multi-tiered infrastructure from bare metal to containerized workloads using declarative configurations and automated workflows.

### Architecture Approach

This infrastructure implements a **dual-strategy architecture**:

| **Traditional Stack** | **Modern Cloud-Native** |
|----------------------|-------------------------|
| ![Terraform](https://img.shields.io/badge/-Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white) Provisions VMs/LXCs | ![Talos](https://img.shields.io/badge/-Talos_Linux-FF6C2C?style=flat-square&logo=talos&logoColor=white) Immutable K8s OS |
| ![Ansible](https://img.shields.io/badge/-Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white) Configures services | ![ArgoCD](https://img.shields.io/badge/-ArgoCD-EF7B4D?style=flat-square&logo=argo&logoColor=white) GitOps deployments |
| Direct node management | ![Gateway API](https://img.shields.io/badge/-Gateway_API-326CE5?style=flat-square&logo=kubernetes&logoColor=white) Modern traffic routing |

---

## Quick Start

### Prerequisites

<table>
<tr>
<td>

**Tools Required**
- [Terraform](https://terraform.io) >= 1.0
- [Ansible](https://ansible.com) >= 2.9
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [talosctl](https://www.talos.dev/v1.7/introduction/getting-started/) >= 1.7.6
- [1Password CLI](https://developer.1password.com/docs/cli/)
- [gh CLI](https://cli.github.com/)

</td>
<td>

**Access Required**
- 1Password vault access
- GitHub account (SSH keys)
- Proxmox VE API credentials
- Network access to home lab

</td>
</tr>
</table>

### Initial Setup

```bash
# Clone repository
git clone https://github.com/TechDufus/home.io.git
cd home.io

# Configure 1Password CLI
op signin

# Install Ansible dependencies
pip install ansible
ansible-galaxy install -r requirements.yml

# Initialize Terraform
cd terraform/proxmox/environments/dev
terraform init
```

---

## Infrastructure Layers

### 1. Hypervisor Layer

<table>
<tr>
<td width="50%">

#### ![Proxmox](https://img.shields.io/badge/-Proxmox_VE-E57000?style=flat-square&logo=proxmox&logoColor=white)

Primary virtualization platform for traditional workloads.

**Location:** `terraform/proxmox/`

**Modules:**
- `proxmox_vm` - Generic VM provisioning
- `proxmox_lxc` - Container provisioning
- `talos-node` - Kubernetes nodes
- `talos-template` - Base templates

</td>
<td width="50%">

#### ![Harvester](https://img.shields.io/badge/-Harvester_HCI-00A19C?style=flat-square&logo=kubernetes&logoColor=white)

Kubernetes-native hyper-converged infrastructure.

**Location:** `terraform/harvester/`

**Purpose:**
- Alternative virtualization layer
- Cloud-native VM management
- Integrated storage and networking

</td>
</tr>
</table>

### 2. Compute Tiers

Standardized node sizing for predictable resource allocation:

| Tier | CPU | Memory | Disk | Use Case |
|------|-----|--------|------|----------|
| **Cumulus** (Small) | 2 cores | 4GB | 60GB | Lightweight services, DNS, monitoring agents |
| **Nimbus** (Medium) | 4 cores | 8GB | 100GB | Application servers, databases, caching layers |
| **Stratus** (Large) | 8 cores | 16GB | 250GB | Kubernetes nodes, heavy workloads, CI/CD |

### 3. Network Architecture

#### Dual-Domain Strategy

```
Internal Network (home.io)          External Access (lab.techdufus.com)
        │                                      │
        ├── *.home.io                         ├── Cloudflare Tunnel
        ├── Local DNS (Pi-hole)               ├── Public DNS
        └── Direct LAN access                 └── Secure remote access
```

#### IP Allocation Scheme

| Range | Purpose | Examples |
|-------|---------|----------|
| `10.0.20.1-9` | Management | Proxmox, switches, APs |
| `10.0.20.10-199` | Kubernetes | Talos nodes, control planes |
| `10.0.20.200-230` | Services | Pi-hole, Portainer, Home Assistant |

#### Network Services

- **DNS:** Dual Pi-hole servers (primary: `10.0.0.99`)
- **Load Balancing:** ![MetalLB](https://img.shields.io/badge/-MetalLB-0078D7?style=flat-square&logo=kubernetes&logoColor=white) with dedicated IP pools
- **Ingress:** ![Gateway API](https://img.shields.io/badge/-Gateway_API-326CE5?style=flat-square&logo=kubernetes&logoColor=white) (replacing traditional Ingress)

### 4. Kubernetes Platform

<div align="center">

![Talos Linux](https://img.shields.io/badge/Talos_Linux-FF6C2C?style=for-the-badge&logo=talos&logoColor=white)
![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)
![Gateway API](https://img.shields.io/badge/Gateway_API-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Traefik](https://img.shields.io/badge/Traefik-24A1C1?style=for-the-badge&logo=traefikproxy&logoColor=white)

</div>

**Components:**
- **OS:** Talos Linux (immutable, API-driven)
- **Provisioning:** Terraform for cluster lifecycle
- **Deployments:** ArgoCD for GitOps workflows
- **Traffic:** Gateway API with Traefik controller
- **Secrets:** 1Password Operator integration
- **CI/CD:** GitHub Actions Runner Controller

---

## Project Structure

```
home.io/
├── terraform/                    # Infrastructure as Code
│   ├── proxmox/                 # Proxmox VE provisioning
│   │   ├── modules/            # Reusable Terraform modules
│   │   │   ├── proxmox_vm/     # Generic VM provisioning
│   │   │   ├── proxmox_lxc/    # LXC container module
│   │   │   ├── talos-node/     # Talos Kubernetes nodes
│   │   │   └── talos-template/ # Talos image templates
│   │   ├── environments/       # Environment-specific configs
│   │   │   └── dev/           # Development environment
│   │   └── scripts/           # Helper scripts
│   │       └── tfstate        # 1Password state management
│   └── harvester/              # Harvester HCI provisioning
│
├── ansible/                     # Configuration Management
│   ├── playbooks/              # Service deployment playbooks
│   ├── roles/                  # Reusable Ansible roles
│   │   ├── common/            # Base configuration
│   │   ├── docker/            # Container runtime
│   │   ├── pihole-primary/    # Primary DNS server
│   │   ├── pihole-secondary/  # Secondary DNS server
│   │   ├── home-assistant/    # Home automation
│   │   ├── dashy/             # Application dashboard
│   │   ├── portainer/         # Container management
│   │   ├── minecraft/         # Game server
│   │   ├── glances/           # System monitoring
│   │   └── [...]              # Additional services
│   └── inventory/              # Environment inventories
│
├── kubernetes/                  # Kubernetes configurations
│   ├── argocd/                # GitOps manifests
│   │   ├── app-of-apps.yaml   # Root application
│   │   ├── apps/              # Application definitions
│   │   │   ├── platform/      # Infrastructure services
│   │   │   └── applications/  # User applications
│   │   ├── manifests/         # Kubernetes resources
│   │   └── values/            # Helm values
│   └── bootstrap/              # Bootstrap scripts
│       ├── argocd.sh          # ArgoCD installation
│       └── setup-secrets.sh   # Secret management setup
│
└── docs/                      # Documentation
```

---

## Essential Operations

### Terraform Workflows

#### Deploy Infrastructure

```bash
# Proxmox VMs and services
cd terraform/proxmox
terraform init
terraform plan
terraform apply

# Talos Kubernetes cluster (dev environment)
cd terraform/proxmox/environments/dev
terraform init && terraform plan && terraform apply

# Harvester infrastructure
cd terraform/harvester
terraform init && terraform plan && terraform apply
```

#### State Management with 1Password

Secure Terraform state storage using 1Password vaults:

```bash
# Check sync status
./terraform/proxmox/scripts/tfstate status

# Push local state to 1Password
./terraform/proxmox/scripts/tfstate push dev

# Pull state from 1Password
./terraform/proxmox/scripts/tfstate pull dev

# Smart sync (auto push/pull based on timestamps)
./terraform/proxmox/scripts/tfstate sync dev

# List all states
./terraform/proxmox/scripts/tfstate list
```

**Features:**
- Secure state storage in 1Password vaults
- Multi-environment support (dev, staging, prod)
- Automatic sync based on timestamps
- State history and backups

### Ansible Workflows

#### Deploy Services

```bash
# Container hosts and Docker
ansible-playbook ansible/playbooks/container-host.yaml

# DNS servers (Pi-hole)
ansible-playbook ansible/playbooks/pihole.yaml

# Proxmox host configuration
ansible-playbook ansible/playbooks/proxmox.yaml

# Flux node deployment
ansible-playbook ansible/playbooks/fluxnode.yml
```

#### Selective Execution

```bash
# Use tags for specific tasks
ansible-playbook ansible/playbooks/container-host.yaml --tags docker

# Limit to specific hosts
ansible-playbook ansible/playbooks/pihole.yaml --limit pihole-primary
```

### Kubernetes GitOps

#### Bootstrap Kubernetes Cluster

```bash
# 1. Deploy Talos cluster with Terraform (see above)

# 2. Setup secrets from 1Password
cd kubernetes/bootstrap
./setup-secrets.sh

# 3. Bootstrap ArgoCD with App-of-Apps
./argocd.sh dev
```

#### Manage Applications

```bash
# Check application status
kubectl get applications -n argocd

# Force sync an application
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": {"sync": {}}}'

# View ArgoCD UI
echo "ArgoCD: https://lab.techdufus.com/argocd"
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d
```

### Secret Management

#### Kubeconfig Sync with 1Password

Automated kubeconfig management using the `kubestate` script (similar to `tfstate` workflow):

```bash
# From dev environment directory
cd terraform/proxmox/environments/dev

# Push to 1Password (after terraform apply)
../scripts/kubestate push dev

# Pull and auto-merge on another machine
../scripts/kubestate pull dev

# Pull to specific file without merging
../scripts/kubestate pull dev --output ~/Downloads/cluster.yaml

# Extract to terraform directory (reverse of push)
../scripts/kubestate extract dev

# Smart sync (auto push/pull based on timestamps)
../scripts/kubestate sync dev
```

**Features:**
- **pull**: Intelligently merges with existing `~/.kube/config`, preserving other contexts
- **extract**: Downloads to terraform directory (solves "Machine A dies" scenario)
- **--output**: Download to specific file without merging
- **sync**: Timestamp-based smart sync
- **--backup**: Create backups before merging

See `terraform/proxmox/environments/dev/README.md` for complete documentation.

### Common Tasks

```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A

# Access Talos nodes
talosctl -n 10.0.20.10 health
talosctl -n 10.0.20.10 dashboard

# View Gateway API resources
kubectl get gateway -A
kubectl get httproute -A

# Check GitHub Actions runners
kubectl get pods -n actions-runner-system
```

---

## Deployed Services

<table>
<tr>
<td width="50%">

### Infrastructure Services

- ![Pi-hole](https://img.shields.io/badge/-Pi--hole-96060C?style=flat-square&logo=pi-hole&logoColor=white) **Pi-hole** - Network-wide ad blocking and DNS
- ![MetalLB](https://img.shields.io/badge/-MetalLB-0078D7?style=flat-square&logo=kubernetes&logoColor=white) **MetalLB** - Kubernetes load balancer
- ![Traefik](https://img.shields.io/badge/-Traefik-24A1C1?style=flat-square&logo=traefikproxy&logoColor=white) **Traefik** - Gateway API controller
- ![Cloudflare](https://img.shields.io/badge/-Cloudflared-F38020?style=flat-square&logo=cloudflare&logoColor=white) **Cloudflared** - Secure tunnel for external access
- ![Local Path Provisioner](https://img.shields.io/badge/-Local_Path-326CE5?style=flat-square&logo=kubernetes&logoColor=white) **Local Path Provisioner** - Dynamic storage
- ![CloudNativePG](https://img.shields.io/badge/-CloudNativePG-336791?style=flat-square&logo=postgresql&logoColor=white) **CloudNativePG** - PostgreSQL operator
- ![Glances](https://img.shields.io/badge/-Glances-5294E2?style=flat-square) **Glances** - System monitoring

</td>
<td width="50%">

### Applications

- ![Dashy](https://img.shields.io/badge/-Dashy-00D1B2?style=flat-square) **Dashy** - Application dashboard
- ![Immich](https://img.shields.io/badge/-Immich-4250AF?style=flat-square&logo=immich&logoColor=white) **Immich** - Photo and video management
- ![Home Assistant](https://img.shields.io/badge/-Home_Assistant-41BDF5?style=flat-square&logo=home-assistant&logoColor=white) **Home Assistant** - Home automation platform
- ![Flux](https://img.shields.io/badge/-Flux_Nodes-00A19C?style=flat-square) **Flux Nodes** - Decentralized computing
- ![GitHub Actions](https://img.shields.io/badge/-GHA_Runners-2088FF?style=flat-square&logo=github-actions&logoColor=white) **GitHub Actions Runners** - Self-hosted CI/CD

**Note:** Portainer and Minecraft server are available but currently disabled.

</td>
</tr>
</table>

---

## Known Issues & Solutions

### MAC Address Regeneration

**Problem:** Terraform regenerates MAC addresses on VM updates, breaking static DHCP leases and SSH known_hosts.

**Solution:** After initial VM creation, add the generated MAC address to your configuration:

```hcl
# Initial deployment (no MAC specified)
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

# Post-deployment (MAC address added)
standalone_vms = {
  n8n-server = {
    vm_id       = 151
    cpu         = 4
    memory      = 4096
    disk_gb     = 50
    ip_address  = "10.0.20.151"
    template    = "ubuntu-24.04-template"
    storage_pool = "VM-SSD-1"
    macaddr     = "06:74:60:C0:37:F6"  # Prevents regeneration
  }
}
```

**Note:** The newer `bpg/proxmox` provider (used in `terraform/proxmox/environments/`) handles MAC addresses more reliably, so this may not be necessary for modern deployments.

---

## Debugging

### Common Issues

<details>
<summary><b>1Password CLI Authentication</b></summary>

**Symptoms:** Terraform fails with authentication errors

**Solution:**
```bash
# Sign in and verify
op signin
op vault list
```
</details>

<details>
<summary><b>Terraform State Conflicts</b></summary>

**Symptoms:** "Resource already exists" errors

**Solution:**
```bash
# Check current state
terraform state list

# Import existing resource
terraform import module.name.resource_type.name resource_id
```
</details>

<details>
<summary><b>Ansible Connection Issues</b></summary>

**Symptoms:** SSH connection refused

**Solution:**
```bash
# Test connectivity
ansible -i inventory/prod all -m ping

# Verify inventory
ansible-inventory -i inventory/prod --list
```
</details>

<details>
<summary><b>Kubernetes Context Problems</b></summary>

**Symptoms:** Cannot connect to cluster

**Solution:**
```bash
# Check contexts
kubectl config get-contexts

# Re-merge kubeconfig from 1Password using automated script
cd terraform/proxmox/environments/dev
../scripts/kubestate pull dev
```
</details>

<details>
<summary><b>Talos Node Issues</b></summary>

**Symptoms:** Node not ready

**Solution:**
```bash
# Check services
talosctl -n <IP> service

# View logs
talosctl -n <IP> logs kubelet

# Interactive dashboard
talosctl -n <IP> dashboard
```
</details>

<details>
<summary><b>ArgoCD Application Won't Sync</b></summary>

**Symptoms:** Application stuck in "Progressing" or "OutOfSync"

**Solution:**
```bash
# Check application status
kubectl describe application <app-name> -n argocd

# View sync logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force sync
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": {"sync": {}}}'
```
</details>

### Debugging Tools

```bash
# Terraform debugging
TF_LOG=DEBUG terraform plan

# Ansible verbose mode
ansible-playbook playbook.yaml -vvv

# Kubernetes diagnostics
kubectl describe node <node-name>
kubectl logs -n <namespace> <pod-name>

# Talos debugging
talosctl -n <IP> dashboard
talosctl -n <IP> logs controller-runtime

# ArgoCD debugging
kubectl logs -n argocd deployment/argocd-server
kubectl get applications -n argocd -o wide

# Gateway API debugging
kubectl get gateway,httproute -A
kubectl describe httproute <route-name> -n <namespace>
```

---

## Development Roadmap

### In Progress
- [ ] Prometheus/Grafana observability stack
- [ ] Centralized logging with Loki
- [ ] Service mesh evaluation (Istio/Linkerd)
- [ ] Automated backup solutions

### Planned
- [ ] PFSense/OPNSense deployment
- [ ] VLAN segmentation
- [ ] Disaster recovery automation
- [ ] Hardware monitoring integration

---

## Security

### Access Control
- All infrastructure credentials managed via ![1Password](https://img.shields.io/badge/-1Password-0094F5?style=flat-square&logo=1password&logoColor=white)
- SSH keys sourced from GitHub
- Kubernetes RBAC enforced
- No hardcoded secrets in repository

### Network Security
- Internal services not exposed directly
- External access via Cloudflare tunnels
- DNS-level ad/malware blocking (Pi-hole)
- VPN for administrative access

### Secret Management
- ![1Password](https://img.shields.io/badge/-1Password-0094F5?style=flat-square&logo=1password&logoColor=white) for credentials and sensitive configs
- Ansible Vault for encrypted playbook variables
- `creds.auto.tfvars` (gitignored) for Terraform
- Kubernetes secrets via 1Password Operator

---

## Contributing

This is a personal home lab project, but suggestions and improvements are welcome!

### Guidelines
- Follow existing code patterns and conventions
- Test changes in dev environment first
- Update documentation for new features
- No hardcoded credentials or secrets
- Use conventional commit format

### Code Standards
- **Terraform:** Lowercase with underscores, clear module structure
- **Ansible:** Kebab-case files, descriptive task names, consistent tags
- **Kubernetes:** Follow K8s naming conventions, include proper labels
- **Commits:** Conventional format (`feat:`, `fix:`, `docs:`, `chore:`)

---

## Resources

### Documentation
- [CLAUDE.md](CLAUDE.md) - Comprehensive project documentation
- [Kubernetes Documentation](kubernetes/CLAUDE.md) - GitOps and K8s details
- [Development Environment](terraform/proxmox/environments/dev/README.md) - Dev setup guide
- Role-specific READMEs in `ansible/roles/`

### External Resources
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Talos Linux Documentation](https://www.talos.dev/latest/)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

## Why Public?

This repository is public to:
- Share infrastructure patterns with the community
- Demonstrate modern home lab practices
- Contribute reusable code and configurations
- Encourage learning and experimentation

While this reveals aspects of my network architecture, the security model doesn't rely on obscurity. All sensitive credentials are managed externally via 1Password, and the infrastructure is designed with defense in depth.

---

## License

This project is provided as-is for educational and reference purposes.

---

<div align="center">

**Built and maintained by [@TechDufus](https://github.com/TechDufus)**

[![GitHub](https://img.shields.io/badge/GitHub-TechDufus-181717?style=for-the-badge&logo=github)](https://github.com/TechDufus)
[![Website](https://img.shields.io/badge/Website-techdufus.com-00A19C?style=for-the-badge)](https://techdufus.com)

</div>
