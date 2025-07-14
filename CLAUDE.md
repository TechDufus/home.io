# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive home lab infrastructure automation project that manages multi-tiered infrastructure using modern DevOps practices. The project orchestrates physical and virtual infrastructure, container platforms, home automation services, and network services through Infrastructure as Code (IaC) and configuration management.

### Project Statistics
- Primary languages: HCL (Terraform), YAML (Ansible/Kubernetes)
- Active since: 2023
- Infrastructure scope: Proxmox VE, Harvester HCI, Kubernetes clusters
- Key maintainer: Matthew DeGarmo (@TechDufus)

## Quick Start

### Prerequisites
- **Operating System**: Linux/macOS (Windows requires WSL)
- **Required Tools**:
  - [Terraform](https://terraform.io) >= 1.0
  - [Ansible](https://ansible.com) >= 2.9
  - [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
  - [talosctl](https://www.talos.dev/v1.7/introduction/getting-started/) >= 1.7.6
  - [1Password CLI](https://developer.1password.com/docs/cli/) configured
  - [gh CLI](https://cli.github.com/) for GitHub operations
- **Accounts**:
  - 1Password with vault access
  - GitHub account (for SSH keys)
  - Proxmox VE API access

### Initial Setup
```bash
# Clone repository
git clone https://github.com/TechDufus/home.io.git
cd home.io

# Configure 1Password CLI
op signin

# Set up Ansible
pip install ansible
ansible-galaxy install -r requirements.yml

# Initialize Terraform (for Proxmox)
cd terraform/proxmox
terraform init
```

## Essential Commands

### Terraform Operations
```bash
# Initialize and apply Proxmox infrastructure
cd terraform/proxmox
terraform init
terraform plan
terraform apply

# Deploy Talos Kubernetes cluster (dev environment)
cd terraform/proxmox/environments/dev
terraform init && terraform plan && terraform apply

# Manage Harvester infrastructure  
cd terraform/harvester
terraform init && terraform plan && terraform apply
```

### Ansible Operations
```bash
# Deploy container hosts and core services
ansible-playbook ansible/playbooks/container-host.yaml
ansible-playbook ansible/playbooks/pihole.yaml
ansible-playbook ansible/playbooks/proxmox.yaml

# Deploy home automation and monitoring
ansible-playbook ansible/playbooks/homeassistant.yaml
ansible-playbook ansible/playbooks/flux.yaml

# Use tags for selective execution
ansible-playbook ansible/playbooks/container-host.yaml --tags docker
```

### CAPI (Modern Kubernetes Management)
```bash
# Bootstrap management cluster (first time only)
cd kubernetes/capi/bootstrap && ./install-capi.sh

# Create workload clusters with addons
./kubernetes/capi/scripts/create-cluster.sh --name dev --env dev --install-addons
./kubernetes/capi/scripts/create-cluster.sh --name prod --env prod --install-addons

# Install GitOps
./kubernetes/capi/scripts/install-argocd.sh --name dev
```

### 1Password Secret Management
```bash
# Bootstrap secret management for clusters
./scripts/1password-bootstrap.sh --name dev --env dev
./scripts/1password-bootstrap.sh --name prod --env prod

# Store kubeconfig in 1Password
op item create --category=Document \
  --title="homelab-dev-kubeconfig" \
  --vault="Personal" \
  kubeconfig=@terraform/proxmox/environments/dev/kubeconfig

# Retrieve kubeconfig on another machine
op document get "homelab-dev-kubeconfig" --vault="Personal" > ~/.kube/config-homelab-dev
```

### Common Tasks
```bash
# Check cluster health
kubectl get nodes --kubeconfig ~/.kube/config-homelab-dev
kubectl get pods -A --kubeconfig ~/.kube/config-homelab-dev

# Access Talos nodes
talosctl -n 10.0.20.10 health
talosctl -n 10.0.20.10 dashboard

# Update Pi-hole configuration
./scripts/download_config.sh
```

## Architecture and Key Concepts

### System Architecture

The project implements a **dual-approach architecture**:

1. **Traditional Infrastructure**: 
   - Terraform provisions VMs/LXCs on Proxmox
   - Ansible configures services and applications
   - Direct management of individual nodes

2. **Modern Cloud-Native**:
   - Cluster API (CAPI) manages Kubernetes lifecycle
   - ArgoCD provides GitOps continuous deployment
   - Gateway API handles modern traffic routing

### Core Infrastructure Components

#### 1. **Hypervisor Layer**
- **Proxmox VE**: Primary virtualization platform
  - Location: `terraform/proxmox/`
  - Modules: `proxmox_vm`, `proxmox_lxc`, `talos-node`, `talos-template`
- **Harvester HCI**: Hyper-converged infrastructure
  - Location: `terraform/harvester/`
  - Purpose: Alternative Kubernetes-native virtualization

#### 2. **Compute Tiers**
Three standardized node types for resource allocation:
- **Cumulus** (Small): 2 CPU, 4GB RAM, 60GB disk
- **Nimbus** (Medium): 4 CPU, 8GB RAM, 100GB disk  
- **Stratus** (Large): 8 CPU, 16GB RAM, 250GB disk

#### 3. **Networking Architecture**
- **Dual-domain strategy**: 
  - Internal: `*.home.io` for local network access
  - External: `*.lab.techdufus.com` via Cloudflare tunnels
- **IP Allocations**:
  - Management: 10.0.20.1-10.0.20.9
  - Kubernetes: 10.0.20.10-10.0.20.199
  - Services: 10.0.20.200-10.0.20.230
- **Load Balancing**: MetalLB with dedicated IP pools
- **DNS**: Pi-hole primary (10.0.0.99) and secondary

#### 4. **Kubernetes Platform**
- **Talos Linux**: Immutable Kubernetes OS
- **Cluster API**: Declarative cluster management
- **Gateway API**: Modern ingress (replacing traditional Ingress)
- **ArgoCD**: GitOps deployment operator

### Data Flow
1. Infrastructure provisioned via Terraform
2. Base configuration applied via Ansible
3. Kubernetes workloads deployed via ArgoCD
4. Services exposed via Gateway API
5. External access through Cloudflare tunnels

## Project Structure

```
home.io/
├── terraform/                    # Infrastructure as Code
│   ├── proxmox/                 # Proxmox VE provisioning
│   │   ├── main.tf             # Main configuration
│   │   ├── variables.tf        # Input variables
│   │   ├── modules/            # Reusable Terraform modules
│   │   │   ├── proxmox_vm/     # Generic VM provisioning
│   │   │   ├── proxmox_lxc/    # LXC container provisioning
│   │   │   ├── talos-node/     # Talos K8s node module
│   │   │   └── talos-template/ # Talos template creation
│   │   └── environments/       # Environment configurations
│   │       └── dev/           # Development environment
│   └── harvester/              # Harvester HCI provisioning
├── ansible/                     # Configuration Management
│   ├── playbooks/              # Ansible playbooks
│   ├── roles/                  # Ansible roles library
│   │   ├── common/            # Base server configuration
│   │   ├── docker/            # Container runtime
│   │   ├── pihole-primary/    # Primary DNS server
│   │   └── [other services]   # Service-specific roles
│   └── inventory/              # Environment inventories
├── kubernetes/                  # Kubernetes configurations
│   ├── argocd/                # GitOps manifests
│   ├── capi/                  # Cluster API configs
│   └── metallb-ipaddresses.yaml
├── scripts/                    # Utility scripts
├── docs/                      # Documentation (planned)
└── CLAUDE.md                  # This file
```

## Important Patterns

### Infrastructure Provisioning Pattern
When adding new infrastructure:
1. Define resources in appropriate Terraform module
2. Use standardized node sizing (Cumulus/Nimbus/Stratus)
3. Add MAC address to vars after initial creation (prevents regeneration)
4. Configure appropriate tags and metadata
5. Run `terraform plan` before applying

Example for new VM:
```hcl
module "new_service" {
  source = "./modules/proxmox_vm"
  
  name        = "service-name"
  node_type   = "nimbus"
  node_count  = 1
  proxmox_node = "proxmox"
  network_bridge = "vmbr0"
  vlan_tag    = 20
  # Add macaddr after first apply to prevent changes
  # macaddr = ["BC:24:11:XX:XX:XX"]
}
```

### Service Deployment Pattern
For new services via Ansible:
1. Create role under `ansible/roles/service-name/`
2. Follow standard role structure (tasks/, vars/, templates/)
3. Create playbook in `ansible/playbooks/`
4. Use tags for granular control
5. Integrate with common role for base configuration

### Kubernetes Workload Pattern
For K8s deployments:
1. Create namespace-specific directory
2. Define manifests following Gateway API patterns
3. Configure ArgoCD application for GitOps
4. Use 1Password operator for secrets
5. Apply via `kubectl` or ArgoCD sync

### Secret Management Pattern
Never commit secrets. Always use:
- 1Password for credentials and sensitive configs
- Ansible Vault for encrypted playbook variables
- Terraform `creds.auto.tfvars` (gitignored)
- Environment variables for runtime secrets

## Code Style

### Terraform Conventions
- **Files**: Lowercase with underscores (e.g., `main.tf`, `variables.tf`)
- **Resources**: Lowercase with underscores
- **Variables**: Lowercase with underscores, descriptive names
- **Modules**: Hyphenated names matching purpose
- **Comments**: Explain "why" not "what"

### Ansible Conventions
- **Playbooks**: Kebab-case YAML files
- **Roles**: Lowercase with underscores
- **Variables**: Lowercase with underscores
- **Tags**: Lowercase, descriptive, consistent
- **Tasks**: Use `name:` with clear descriptions

### Kubernetes Conventions
- **Resources**: Follow K8s naming conventions
- **Labels**: Include environment, app, version
- **Namespaces**: Environment-prefixed
- **Files**: Resource-type naming (e.g., `deployment.yaml`)

### Commit Conventions
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Keep commits atomic and focused
- Reference issues when applicable
- No emojis or personal attribution

## Hidden Context

### MAC Address Regeneration Issue
Terraform regenerates MAC addresses on VM updates, breaking static DHCP leases and SSH known_hosts. **Solution**: After initial VM creation, add the generated MAC address to your `.tfvars`:
```hcl
macaddr = ["BC:24:11:XX:XX:XX"]
```

### Proxmox Provider Quirks
- Using `telmate/proxmox v3.0.1-rc1` for specific features
- Dev environment uses newer `bpg/proxmox` provider
- Both providers have different authentication methods

### Talos Linux Constraints
- No SSH access - use `talosctl` exclusively
- Configuration is immutable - changes require node reboot
- Upgrades are in-place with automatic rollback

### FluxNode Manual Steps
The Ansible role installs prerequisites, but FluxOS requires manual installation via their script. This is intentional to ensure you accept their terms.

### Network Architecture Decisions
- Dual DNS servers for redundancy
- Separate VLANs planned but not yet implemented
- Gateway API chosen over traditional Ingress for future-proofing

### Historical Context
The project evolved from traditional VM management to Kubernetes-native:
1. Started with basic Proxmox + Ansible
2. Added Kubernetes clusters manually
3. Migrated to Cluster API for K8s lifecycle
4. Implementing GitOps with ArgoCD
5. Moving from Ingress to Gateway API

### Known Technical Debt
- No automated testing infrastructure
- CI/CD pipeline not implemented
- Some services still require manual configuration
- Documentation scattered across multiple READMEs
- Mixed provider versions in Terraform

## Debugging Guide

### Common Issues

1. **1Password CLI Authentication**
   - Symptoms: Terraform fails with authentication errors
   - Solution: Run `op signin` and ensure session is active
   - Check: `op vault list` should show your vaults

2. **Terraform State Conflicts**
   - Symptoms: Resource already exists errors
   - Solution: Check state with `terraform state list`
   - Import existing: `terraform import module.name.resource_type.name resource_id`

3. **Ansible Connection Issues**
   - Symptoms: SSH connection refused
   - Solution: Verify inventory IPs and SSH keys
   - Debug: `ansible -i inventory/prod all -m ping`

4. **Kubernetes Context Problems**
   - Symptoms: Cannot connect to cluster
   - Solution: Check `kubectl config get-contexts`
   - Fix: Re-merge kubeconfig from 1Password

5. **Talos Node Issues**
   - Symptoms: Node not ready
   - Check: `talosctl -n <IP> service`
   - Logs: `talosctl -n <IP> logs kubelet`

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
```

## Development Workflows

### Adding New Infrastructure
1. Create feature branch: `feat/service-name`
2. Develop Terraform module or update configuration
3. Test in dev environment first
4. Document any new variables or patterns
5. Create PR with descriptive title
6. Apply to production after validation

### Updating Services
1. Test Ansible changes with `--check` flag
2. Use `--limit` to target specific hosts
3. Verify service health after deployment
4. Update documentation if behavior changes

### GitOps Workflow
1. Make changes to K8s manifests
2. Commit to repository
3. ArgoCD detects and syncs changes
4. Monitor deployment in ArgoCD UI
5. Rollback via Git if issues arise

## Security Notes

### Access Control
- All infrastructure access via 1Password
- No hardcoded credentials in code
- SSH keys pulled from GitHub
- Kubernetes RBAC enforced

### Network Security
- Internal services not exposed directly
- Cloudflare tunnels for external access
- Pi-hole for DNS filtering
- VPN for administrative access

### Secret Management
- 1Password for all credentials
- Ansible Vault for playbook secrets
- Kubernetes secrets via 1Password operator
- Regular secret rotation recommended

## Monitoring and Observability

### Current Monitoring
- Glances for system metrics
- Portainer for container management
- Kubernetes metrics via `kubectl top`
- Talos dashboard for node health

### Planned Improvements
- Prometheus/Grafana stack
- Centralized logging with Loki
- Alertmanager for notifications
- Service mesh observability

## Resources

### Internal Documentation
- [Development Environment README](terraform/proxmox/environments/dev/README.md)
- Individual Ansible role READMEs
- Inline Terraform documentation

### External Resources
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Talos Linux Docs](https://www.talos.dev/latest/)
- [Cluster API Book](https://cluster-api.sigs.k8s.io/)
- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)

### Community
- GitHub Issues for bug reports
- Project maintainer: @TechDufus

## Maintenance Tasks

### Regular Maintenance
- **Weekly**: Check for security updates
- **Monthly**: Review resource utilization
- **Quarterly**: Update dependencies
- **Yearly**: Review and update documentation

### Update Procedures
```bash
# Update Terraform providers
terraform init -upgrade

# Update Ansible roles
ansible-galaxy install -r requirements.yml --force

# Update Kubernetes components
# Via ArgoCD or manual kubectl apply
```

## Contributing Guidelines

### Code Submission Process
1. Fork repository (if external contributor)
2. Create feature branch
3. Follow existing patterns and conventions
4. Test thoroughly in dev environment
5. Submit PR with clear description
6. Respond to review feedback

### Quality Standards
- Code must follow established patterns
- Changes must be tested
- Documentation must be updated
- No hardcoded values or secrets
- Consider backward compatibility