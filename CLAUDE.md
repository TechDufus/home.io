# home.io

Home lab infrastructure: Proxmox VE → Ubuntu 24.04 VMs (Terraform) → k3s → ArgoCD (GitOps).

- Languages: HCL (Terraform), YAML (Kubernetes)
- GitOps: ArgoCD app-of-apps pattern
- Maintainer: Matthew DeGarmo (@TechDufus)

## Stack

```
Proxmox VE → Ubuntu 24.04 VMs (cloud-init, Terraform)
  └── k3s (--disable traefik,servicelb,local-storage)
      └── ArgoCD (annotation-based tracking)
          ├── Platform: Longhorn, Tailscale Operator, NFS CSI Driver
          └── Applications: Immich
```

## Nodes

| Node | Role | CPU | RAM | IP |
|------|------|-----|-----|----|
| k3s-cp-1 | Control plane | 4 | 8GB | 10.0.20.20 |
| k3s-worker-1 | Worker | 4 | 16GB | 10.0.20.21 |
| k3s-worker-2 | Worker | 4 | 16GB | 10.0.20.22 |

## Where to Look

| Task | Location |
|------|----------|
| Provision/modify VMs | `terraform/proxmox/environments/dev/` |
| Add Terraform module | `terraform/proxmox/modules/` |
| Add K8s application | `kubernetes/argocd/apps/applications/` |
| Add platform service | `kubernetes/argocd/apps/platform/` |
| Helm values | `kubernetes/argocd/values/` |
| App manifests | `kubernetes/argocd/manifests/<app>/` |
| Bootstrap cluster | `kubernetes/bootstrap/` |

## Prerequisites

- Terraform >= 1.0, kubectl >= 1.28, Helm >= 3.0
- 1Password CLI (`op`) configured
- gh CLI for GitHub operations
- Proxmox VE API access

## Development Workflow

1. Feature branch: `feat/description`
2. Terraform changes: `terraform plan` → `terraform apply`
3. K8s changes: commit and push — ArgoCD auto-syncs
4. Create PR against `main`

## Code Style

### Terraform
- Files: lowercase with underscores (`main.tf`, `variables.tf`)
- Provider: `bpg/proxmox`

### Kubernetes YAML
- 2-space indent, kebab-case naming, `app` label required

### Commits
- Conventional: `feat:`, `fix:`, `docs:`, `chore:`
- Atomic, focused, no emojis

## Hidden Context

### k3s Disabled Components
Traefik, ServiceLB, local-storage all disabled — replaced by Tailscale Operator and Longhorn.

### Standalone VMs
Terraform also provisions non-k3s VMs (n8n-server, openclaw).

### NFS CSI Driver Issues
NFS CSI driver hangs after UNAS firmware updates. Immich library uses static native NFS volume. Do not convert back to CSI. See `kubernetes/CLAUDE.md` for details.

## Security

- All credentials via 1Password — never hardcoded
- No public endpoints — Tailscale-only access
- SSH keys from GitHub for VM provisioning
- `creds.auto.tfvars` is gitignored

## Nested Guidance

Context-specific guidance in `terraform/CLAUDE.md` and `kubernetes/CLAUDE.md`.
These load automatically when working in those directories.
