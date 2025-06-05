# Environment Structure (Dev & Prod Only)

## Overview

The infrastructure supports two environments:
- **Development (dev)**: Testing and development workloads
- **Production (prod)**: Production workloads

## Cluster Naming Convention

- **Development**: `dev`
- **Production**: `prod`

## URL Patterns

### Internal Access (*.home.io)
- **Development**: `service.dev.home.io`
- **Production**: `service.prod.home.io`

### External Access (*.lab.techdufus.com)
- **Development**: `service.dev.lab.techdufus.com`
- **Production**: `service.prod.lab.techdufus.com`

## 1Password Vault Structure

```
cicd Vault
├── Infrastructure/
│   ├── dev-proxmox-api-token
│   ├── dev-proxmox-api-endpoint
│   ├── dev-ssh-private-key
│   ├── dev-ssh-public-key
│   ├── prod-proxmox-api-token
│   ├── prod-proxmox-api-endpoint
│   ├── prod-ssh-private-key
│   └── prod-ssh-public-key
├── Service-Accounts/
│   ├── 1password-operator-dev
│   └── 1password-operator-prod
├── External-Services/
│   ├── dev-cloudflare-dns-token
│   ├── prod-cloudflare-dns-token
│   ├── github-argocd-token
│   ├── github-argocd-prod-token
│   ├── slack-monitoring-webhook
│   └── pagerduty-alerting
└── Applications/
    ├── dev-argocd-admin
    ├── dev-grafana-admin
    ├── dev-postgresql-credentials
    ├── dev-redis-auth
    ├── prod-argocd-admin
    ├── prod-grafana-oidc
    ├── prod-postgresql-credentials
    └── prod-redis-auth
```

## Environment-Specific Configurations

### Development Environment
- **Purpose**: Testing, development, experimentation
- **Security**: Relaxed for development velocity
- **Secrets**: Development-grade credentials
- **Monitoring**: Basic monitoring for debugging
- **Access**: Open access for development team

### Production Environment
- **Purpose**: Live workloads and services
- **Security**: Hardened security policies
- **Secrets**: Production-grade credentials with rotation
- **Monitoring**: Full monitoring with alerting
- **Access**: Restricted access with RBAC

## Secret Reference Files

- `dev-secrets.yaml`: Development environment secrets
- `prod-secrets.yaml`: Production environment secrets

## Bootstrap Commands

### Development
```bash
# Bootstrap development environment
./scripts/1password-bootstrap.sh --name dev --env dev

# Create development cluster
./kubernetes/capi/scripts/create-cluster.sh \
  --name dev --env dev --install-addons --use-1password
```

### Production
```bash
# Bootstrap production environment
./scripts/1password-bootstrap.sh --name prod --env prod

# Create production cluster
./kubernetes/capi/scripts/create-cluster.sh \
  --name prod --env prod --install-addons --use-1password
```

## Service Examples

### ArgoCD
- **Development**: `argocd.dev.lab.techdufus.com`
- **Production**: `argocd.prod.lab.techdufus.com`

### Grafana
- **Development**: `grafana.dev.lab.techdufus.com`
- **Production**: `grafana.prod.lab.techdufus.com`

### Custom Applications
- **Development**: `myapp.dev.lab.techdufus.com`
- **Production**: `myapp.prod.lab.techdufus.com`

## Security Considerations

### Development
- Self-signed certificates acceptable
- Basic authentication sufficient
- Network policies recommended but not required
- Logging for debugging purposes

### Production
- Valid TLS certificates required
- Strong authentication (OIDC/LDAP)
- Network policies enforced
- Comprehensive logging and monitoring
- Regular security audits

## Promotion Workflow

1. **Develop** in dev environment
2. **Test** thoroughly in dev environment
3. **Deploy** to production environment
4. **Monitor** production deployment

No staging environment - direct dev to prod promotion with proper testing and validation.