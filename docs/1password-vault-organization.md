# 1Password Vault Organization for CAPI Clusters

## Vault Structure

### cicd Vault (Infrastructure Secrets)
```
cicd/
├── Infrastructure/
│   ├── proxmox-api-credentials      # Proxmox API token and endpoint
│   ├── ssh-private-keys            # SSH keys for VM access
│   ├── cloudflare-api-tokens       # DNS and tunnel management
│   └── container-registry-tokens   # Harbor/DockerHub credentials
├── Service-Accounts/
│   ├── 1password-operator-dev      # Dev cluster operator token
│   ├── 1password-operator-prod     # Prod cluster operator token
│   └── 1password-bootstrap-token   # Bootstrap script access
├── Certificates/
│   ├── ca-certificates             # Internal CA certs
│   ├── wildcard-tls-certs          # *.home.io certificates
│   └── service-mesh-certs          # Istio/Linkerd certificates
└── External-Services/
    ├── github-tokens               # GitHub API tokens
    ├── docker-hub-credentials      # Container registry access
    └── monitoring-webhooks         # Slack/Discord webhooks
```

### Personal Vault (Development & Testing)
```
Personal/
├── Development/
│   ├── local-cluster-secrets       # Kind/k3s development
│   ├── testing-api-keys            # Non-production APIs
│   └── dev-database-credentials    # Local database access
└── SSH-Keys/
    ├── personal-ssh-keys           # Personal development keys
    └── github-ssh-keys             # Git repository access
```

## Service Account Strategy

### 1. Bootstrap Service Account
- **Purpose**: Initial cluster creation and 1Password operator deployment
- **Permissions**: Read-only access to cicd vault Infrastructure and Service-Accounts sections
- **Lifetime**: Long-lived (rotated quarterly)
- **Usage**: CAPI bootstrap scripts

### 2. Cluster-Specific Service Accounts
- **Purpose**: Runtime secret access for deployed applications
- **Permissions**: Read-only access to specific secret categories
- **Lifetime**: Medium-lived (rotated monthly)
- **Usage**: 1Password Secret Operator in each cluster

### 3. Emergency Access Account
- **Purpose**: Break-glass access for disaster recovery
- **Permissions**: Full access to cicd vault
- **Lifetime**: Long-lived (rotated annually)
- **Usage**: Manual recovery procedures

## Secret Naming Convention

### Infrastructure Secrets
- `{environment}-{component}-{type}`: `prod-proxmox-api-token`
- `{cluster}-{service}-{credential}`: `dev-argocd-admin-password`

### Service Account Tokens
- `1password-operator-{cluster}`: `1password-operator-dev`
- `bootstrap-token-{environment}`: `bootstrap-token-production`

### External API Keys
- `{service}-{environment}-{type}`: `cloudflare-prod-dns-token`
- `{provider}-{purpose}-key`: `github-argocd-webhook-token`

## Access Patterns

### Least Privilege Matrix
```
Service Account          | Infrastructure | Service-Accounts | Certificates | External-Services
-------------------------|---------------|------------------|--------------|------------------
bootstrap-token          | Read          | Read (limited)   | Read         | Read (limited)
1password-operator-dev   | None          | Read (own)       | Read         | Read (dev only)
1password-operator-prod  | None          | Read (own)       | Read         | Read (prod only)
emergency-access         | Full          | Full             | Full         | Full
```

### Secret Categories by Environment
```yaml
Development:
  - SSH keys (temporary)
  - API tokens (sandbox)
  - Database credentials (local)
  - TLS certificates (self-signed)

Production:
  - SSH keys (production)
  - API tokens (production)
  - Database credentials (production)
  - TLS certificates (production CA)
```