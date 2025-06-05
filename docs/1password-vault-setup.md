# 1Password Vault Setup Guide

## Required Vault Structure

Your 1Password setup should have the following structure:

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

## Setting Up Secrets

### Using 1Password Web Interface

1. Navigate to your cicd vault
2. Create items with appropriate categories and names
3. Use appropriate categories:
   - **API Credential** for tokens and API keys
   - **Password** for passwords and secrets
   - **SSH Key** for SSH private/public keys
   - **Secure Note** for complex configurations

### Using 1Password CLI

```bash
# Example: Create Proxmox API token
op item create \
  --category="API Credential" \
  --title="Infrastructure/dev-proxmox-api-token" \
  --vault="cicd" \
  token="pvt_xxxxx" \
  secret="xxxxx-xxxxx-xxxxx"

# Example: Create SSH key pair
op item create \
  --category="SSH Key" \
  --title="Infrastructure/dev-ssh-private-key" \
  --vault="cicd" \
  private_key="$(cat ~/.ssh/id_rsa)"

# Example: Create ArgoCD admin password
op item create \
  --category="Password" \
  --title="Applications/dev-argocd-admin" \
  --vault="cicd" \
  password="secure-random-password"
```

## Service Account Creation

1. **Create Service Account in 1Password**
   - Go to Settings → Service Accounts
   - Create service account with name: `CAPI-Bootstrap-{Environment}`
   - Grant access to cicd vault with specific permissions

2. **Configure Permissions**
   - Read access to all items in cicd vault
   - No write permissions for security
   - Set appropriate expiration

3. **Save Service Account Token**
   ```bash
   # Export token for bootstrap script
   export OP_SERVICE_ACCOUNT_TOKEN="ops_xxxxx"
   ```

## Required Fields per Secret Type

### Infrastructure Secrets
- **Proxmox API Token**
  - `token`: API token value
  - `secret`: API secret value
  - `url`: Proxmox endpoint URL

- **SSH Keys**
  - `private_key`: SSH private key content
  - `public_key`: SSH public key content

### Application Secrets
- **Database Credentials**
  - `username`: Database username
  - `password`: Database password
  - `host`: Database host (optional)
  - `port`: Database port (optional)

- **API Tokens**
  - `token` or `api-key`: The actual token value
  - `endpoint`: API endpoint URL (if applicable)

### Service Integration
- **Cloudflare**
  - `token`: DNS API token
  - `zone-id`: Zone ID (optional)

- **GitHub**
  - `token`: Personal access token or app token
  - `username`: GitHub username (if applicable)

## Validation Commands

```bash
# Test service account access
op vault list

# Verify specific secret exists
op item get "Infrastructure/dev-proxmox-api-token" --vault="cicd"

# List all secrets in cicd vault
op item list --vault="cicd"

# Validate bootstrap script
./scripts/1password-bootstrap.sh --name dev --env dev --validate-only
```

## Security Best Practices

1. **Naming Convention**: Use clear folder structure (Infrastructure/, Service-Accounts/, etc.)
2. **Environment Separation**: Use clear environment prefixes (dev-, prod-)
3. **Service Accounts**: Use separate service accounts per environment
4. **Regular Rotation**: Rotate service account tokens quarterly
5. **Audit Access**: Review service account usage monthly

## Troubleshooting

### Common Issues

1. **Item Not Found**
   ```bash
   # Check exact item name
   op item list --vault="Personal" | grep "myitem"
   
   # Verify service account permissions
   op vault get "Personal"
   ```

2. **Permission Denied**
   ```bash
   # Verify service account token
   echo $OP_SERVICE_ACCOUNT_TOKEN | cut -c1-10
   
   # Check vault access
   op vault get "cicd"
   ```

3. **Bootstrap Validation Fails**
   ```bash
   # Run with debug output
   ./scripts/1password-bootstrap.sh --name dev --env dev --validate-only --dry-run
   ```