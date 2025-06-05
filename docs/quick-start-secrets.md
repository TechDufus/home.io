# Quick Start: Creating Minimum Required Secrets

This guide helps you create the bare minimum 1Password secrets needed to bootstrap your first CAPI cluster.

## Prerequisites

1. **1Password CLI installed and authenticated**
   ```bash
   # Install 1Password CLI (macOS)
   brew install 1password-cli
   
   # Sign in to 1Password
   op signin
   ```

2. **cicd vault created in 1Password**
   - Create a vault named "cicd" in your 1Password account
   - This will store all infrastructure secrets

## Method 1: Automated Dummy Secret Creation

Use the provided script to create all required secrets with dummy values:

```bash
# Create dummy secrets for development environment
./scripts/create-dummy-secrets.sh --env dev

# See what would be created first (dry run)
./scripts/create-dummy-secrets.sh --env dev --dry-run
```

This creates 6 secrets with dummy values that you can update later.

## Method 2: Manual Secret Creation

### 1. Proxmox Infrastructure Access

```bash
# Proxmox API credentials
op item create \
  --category="API Credential" \
  --title="Infrastructure/dev-proxmox-api-token" \
  --vault="cicd" \
  token="YOUR_PROXMOX_API_TOKEN" \
  secret="YOUR_PROXMOX_API_SECRET"

# Proxmox endpoint
op item create \
  --category="API Credential" \
  --title="Infrastructure/dev-proxmox-api-endpoint" \
  --vault="cicd" \
  url="https://your-proxmox-host:8006"
```

### 2. SSH Access for VMs

```bash
# SSH private key
op item create \
  --category="SSH Key" \
  --title="Infrastructure/dev-ssh-private-key" \
  --vault="cicd" \
  private_key="$(cat ~/.ssh/id_rsa)"

# SSH public key
op item create \
  --category="SSH Key" \
  --title="Infrastructure/dev-ssh-public-key" \
  --vault="cicd" \
  public_key="$(cat ~/.ssh/id_rsa.pub)"
```

### 3. 1Password Operator Service Account

```bash
# Create service account token for cluster operator
op item create \
  --category="API Credential" \
  --title="Service-Accounts/1password-operator-dev" \
  --vault="cicd" \
  token="YOUR_CLUSTER_SERVICE_ACCOUNT_TOKEN"
```

### 4. Cloudflare DNS (Optional)

```bash
# Cloudflare API token for DNS management
op item create \
  --category="API Credential" \
  --title="External-Services/dev-cloudflare-dns-token" \
  --vault="cicd" \
  token="YOUR_CLOUDFLARE_API_TOKEN"
```

## Real Values You Need

### Critical (Required for cluster creation):

1. **Proxmox API Token & Secret**
   - Get from Proxmox: Datacenter → API Tokens → Add
   - Format: `PVEAPIToken=user@realm!tokenid=uuid`

2. **Proxmox API Endpoint**
   - Your Proxmox server URL: `https://proxmox.example.com:8006`

3. **SSH Key Pair**
   - Use existing keys: `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`
   - Or generate new: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/capi_rsa`

4. **1Password Service Account Token**
   - Create in 1Password: Settings → Service Accounts
   - Grant read access to cicd vault
   - Format: `ops_xxxxxxxxxxxxxxxxxx`

### Optional (Can add later):

5. **Cloudflare API Token**
   - Get from Cloudflare: My Profile → API Tokens → Create Token
   - Template: "Custom token" with Zone:Read, DNS:Edit permissions

## Validation

After creating secrets, validate they're accessible:

```bash
# Test 1Password access
op vault get cicd

# List all secrets in cicd vault
op item list --vault=cicd

# Validate specific secret
op item get "Infrastructure/dev-proxmox-api-token" --vault=cicd

# Test bootstrap script validation
export OP_SERVICE_ACCOUNT_TOKEN="your_bootstrap_token"
./scripts/1password-bootstrap.sh --name dev --env dev --validate-only
```

## Service Account Setup

You need **two** service accounts:

1. **Bootstrap Service Account** (for running scripts)
   - Access: Read-only to entire cicd vault
   - Use: Set as `OP_SERVICE_ACCOUNT_TOKEN` environment variable

2. **Cluster Service Account** (for 1Password operator in cluster)
   - Access: Read-only to cicd vault
   - Use: Store in `Service-Accounts/1password-operator-dev`

## Common Issues

### "Item not found"
- Check exact secret titles match the expected format
- Verify secrets are in the "cicd" vault, not "Personal" or other vaults

### "Permission denied"
- Ensure service account has read access to cicd vault
- Check service account token is not expired

### "Authentication failed"
- Verify `OP_SERVICE_ACCOUNT_TOKEN` is set correctly
- Test with `op vault list`

## Next Steps

Once secrets are created and validated:

1. **Bootstrap the environment:**
   ```bash
   ./scripts/1password-bootstrap.sh --name dev --env dev
   ```

2. **Create the cluster:**
   ```bash
   ./kubernetes/capi/scripts/create-cluster.sh \
     --name dev --env dev --install-addons --use-1password
   ```

3. **Add application secrets as needed** (ArgoCD, Grafana, etc.)

## Production Secrets

For production, repeat the process with `--env prod`:

```bash
# Create production dummy secrets
./scripts/create-dummy-secrets.sh --env prod

# Or manually create with "prod" prefix instead of "dev"
```

Remember to use different, more secure credentials for production!