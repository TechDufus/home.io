# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Home lab infrastructure automation project running a k3s Kubernetes cluster on Proxmox VE. The stack is intentionally simple: Terraform provisions Ubuntu VMs, k3s provides Kubernetes, and ArgoCD handles GitOps deployment of a small set of platform services and applications.

- Primary languages: HCL (Terraform), YAML (Kubernetes)
- Infrastructure: Proxmox VE → Ubuntu 24.04 VMs → k3s
- GitOps: ArgoCD with app-of-apps pattern
- Key maintainer: Matthew DeGarmo (@TechDufus)

## Quick Start

### Prerequisites
- [Terraform](https://terraform.io) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28
- [Helm](https://helm.sh/) >= 3.0
- [1Password CLI](https://developer.1password.com/docs/cli/) configured
- [gh CLI](https://cli.github.com/) for GitHub operations
- Proxmox VE API access

### Initial Setup
```bash
git clone https://github.com/TechDufus/home.io.git
cd home.io

# Sign in to 1Password
op signin

# Provision VMs with Terraform
cd terraform/proxmox/environments/dev
terraform init && terraform plan && terraform apply

# Install k3s on VMs (manual — see kubernetes/bootstrap/README.md)
# Then bootstrap the cluster
cd kubernetes/bootstrap
./setup-secrets.sh
./argocd.sh
```

## Essential Commands

### Terraform
```bash
cd terraform/proxmox/environments/dev
terraform init
terraform plan
terraform apply
```

### Kubernetes / k3s
```bash
# Cluster health
kubectl get nodes
kubectl get pods -A

# Resource usage
kubectl top nodes
kubectl top pods -A

# ArgoCD status
kubectl get applications -n argocd

# Force sync an application
kubectl patch application <app-name> -n argocd \
  --type merge -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {}}}'

# ArgoCD UI (port-forward)
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Longhorn UI (port-forward)
kubectl port-forward svc/longhorn-frontend -n longhorn-system 9090:80

# Tailscale operator status
kubectl get pods -n tailscale

# Immich status
kubectl get pods -n immich
```

### 1Password Secret Management
```bash
# Bootstrap secrets for the cluster
cd kubernetes/bootstrap
./setup-secrets.sh
```

## Architecture

### Stack
```
Proxmox VE (hypervisor)
  └── Ubuntu 24.04 VMs (cloud-init, Terraform-provisioned)
      └── k3s (--disable traefik,servicelb,local-storage)
          └── ArgoCD (Helm-installed, annotation-based tracking)
              ├── Platform: Longhorn, Tailscale Operator, NFS CSI Driver
              └── Applications: Immich
```

### Nodes
| Node | Role | CPU | RAM | Disk | IP |
|------|------|-----|-----|------|----|
| k3s-cp-1 | Control plane | 4 | 8GB | 40GB | 10.0.20.20 |
| k3s-worker-1 | Worker | 4 | 16GB | 100GB | 10.0.20.21 |
| k3s-worker-2 | Worker | 4 | 16GB | 100GB | 10.0.20.22 |

### Networking
- **Service exposure**: Tailscale Operator (`loadBalancerClass: tailscale`)
- **No public endpoints**: All access via Tailscale MagicDNS
- **DNS**: Pi-hole primary (10.0.0.99), fallback 1.1.1.1 / 1.0.0.1
- **Gateway**: 10.0.20.1, subnet /24

### Storage
- **Longhorn**: Distributed block storage (2 replicas) for stateful workloads
- **NFS CSI Driver**: Mounts from UNAS NAS at 10.0.0.254

### Platform Services (ArgoCD-managed)
| Service | Purpose |
|---------|---------|
| Longhorn | Block storage with replication |
| Tailscale Operator | Service exposure via Tailscale |
| NFS CSI Driver | NFS volume provisioning |

### Applications (ArgoCD-managed)
| App | Purpose |
|-----|---------|
| Immich | Photo management with standalone Postgres + Valkey |

## Project Structure

```
home.io/
├── terraform/
│   └── proxmox/
│       ├── modules/
│       │   ├── proxmox_vm/          # VM provisioning module
│       │   └── proxmox_lxc/         # LXC container module
│       └── environments/
│           └── dev/                 # k3s cluster + standalone VMs
│               ├── vms.tf           # VM definitions
│               ├── providers.tf     # bpg/proxmox provider
│               └── terraform.tfvars # Node sizing and IPs
├── kubernetes/
│   ├── bootstrap/
│   │   ├── argocd.sh              # Helm-install ArgoCD + app-of-apps
│   │   ├── setup-secrets.sh       # 1Password → K8s secrets
│   │   └── README.md              # k3s install instructions
│   └── argocd/
│       ├── app-of-apps.yaml       # Root ArgoCD application
│       ├── apps/
│       │   ├── platform/          # Longhorn, Tailscale, NFS CSI
│       │   └── applications/      # Immich
│       ├── manifests/
│       │   ├── immich/            # Postgres StatefulSet, PVCs, Tailscale svc
│       │   └── tailscale/         # Namespace
│       └── values/                # Helm values for all charts
│           ├── argocd.yaml
│           ├── longhorn.yaml
│           ├── tailscale-operator.yaml
│           ├── csi-driver-nfs.yaml
│           └── immich.yaml
├── scripts/                       # Utility scripts
└── CLAUDE.md
```

## Important Patterns

### Adding a VM (Terraform)
VMs are defined in `terraform/proxmox/environments/dev/vms.tf` using the `standalone_vms` pattern:
1. Add VM definition to the locals or module block
2. Specify CPU, memory, disk, IP, and cloud-init template
3. Run `terraform plan` then `terraform apply`
4. After first apply, pin the MAC address in tfvars to prevent regeneration

### Adding a Kubernetes Application
1. Create ArgoCD Application in `kubernetes/argocd/apps/platform/` or `apps/applications/`
2. Add Helm values in `kubernetes/argocd/values/`
3. Add supporting manifests (namespace, PVCs, etc.) in `kubernetes/argocd/manifests/<app>/`
4. To expose via Tailscale, create a LoadBalancer service with `loadBalancerClass: tailscale`
5. Commit — ArgoCD auto-syncs from the repository

### Exposing a Service via Tailscale
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service-tailscale
  namespace: my-service
spec:
  type: LoadBalancer
  loadBalancerClass: tailscale
  selector:
    app: my-service
  ports:
    - port: 80
      targetPort: 8080
```

### Secret Management
- 1Password CLI (`op`) for all credentials
- Bootstrap script (`kubernetes/bootstrap/setup-secrets.sh`) creates K8s secrets from 1Password
- Terraform uses `creds.auto.tfvars` (gitignored)
- Never commit secrets to the repository

## Code Style

### Terraform
- Files: lowercase with underscores (`main.tf`, `variables.tf`)
- Provider: `bpg/proxmox`
- Comments: explain "why" not "what"

### Kubernetes YAML
- Indentation: 2 spaces
- Resource naming: kebab-case (`my-service`)
- Labels: include `app` at minimum

### Commits
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Atomic and focused
- No emojis or attribution

## Hidden Context

### MAC Address Regeneration
Terraform regenerates MAC addresses on VM updates, breaking DHCP leases. Pin MAC addresses in tfvars after initial creation.

### ArgoCD Tracking Method
Must use annotation-based resource tracking (not label-based). Label tracking causes issues with certain controllers. Configured in `argocd-cm` ConfigMap via `application.resourceTrackingMethod: annotation`.

### k3s Disabled Components
k3s is installed with `--disable traefik --disable servicelb --disable local-storage` because:
- Traefik replaced by Tailscale Operator for service exposure
- ServiceLB replaced by Tailscale's loadBalancerClass
- Local-storage replaced by Longhorn

### NFS CSI Driver Limitations
The NFS CSI driver hangs on mount operations after UNAS firmware updates. The immich-library PV uses a static native NFS volume (`spec.nfs`) instead of CSI to avoid this. Do not convert it back to CSI. See `kubernetes/CLAUDE.md` for full details and debugging steps.

### Standalone VMs
Besides k3s nodes, the Terraform config also provisions standalone VMs (n8n-server, openclaw) that are not part of the k3s cluster.

## Debugging Guide

### 1Password CLI
- Symptom: Terraform or bootstrap fails with auth errors
- Fix: `op signin` and verify with `op vault list`

### Terraform State
- Symptom: "resource already exists" errors
- Fix: `terraform state list` to inspect, `terraform import` if needed

### ArgoCD Sync Issues
- Symptom: Application stuck in "Progressing"
- Check: `kubectl describe application <app> -n argocd`
- Logs: `kubectl logs -n argocd deployment/argocd-application-controller`

### Longhorn Volume Issues
- Check: `kubectl get volumes -n longhorn-system`
- UI: `kubectl port-forward svc/longhorn-frontend -n longhorn-system 9090:80`

### Tailscale Service Not Accessible
- Check: `kubectl get svc -A | grep tailscale`
- Pods: `kubectl get pods -n tailscale`
- Logs: `kubectl logs -n tailscale -l app=tailscale-operator`

### k3s Node Issues
- SSH into node: `ssh ubuntu@10.0.20.2X`
- Service status: `sudo systemctl status k3s` (or `k3s-agent` on workers)
- Logs: `sudo journalctl -u k3s -f`

### General Kubernetes
```bash
kubectl describe node <node-name>
kubectl logs -n <namespace> <pod-name>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Development Workflow

1. Create feature branch: `feat/description`
2. Make changes to Terraform or Kubernetes manifests
3. For Terraform: `terraform plan` → `terraform apply`
4. For Kubernetes: commit and push — ArgoCD auto-syncs
5. Verify in ArgoCD UI or via `kubectl get applications -n argocd`
6. Create PR against `main`

## Security

- All credentials via 1Password — never hardcoded
- No public endpoints — Tailscale-only access
- SSH keys pulled from GitHub for VM provisioning
- Kubernetes RBAC enforced

## Resources

- [Proxmox VE Docs](https://pve.proxmox.com/pve-docs/)
- [k3s Docs](https://docs.k3s.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Longhorn Docs](https://longhorn.io/docs/)
- [Tailscale Operator Docs](https://tailscale.com/kb/1236/kubernetes-operator)
