#!/bin/bash
# Setup Kubernetes secrets from 1Password
# This script detects required secrets and creates them in the appropriate namespaces
# Usage: ./setup-secrets.sh [dev|prod]

set -e

ENV=${1:-dev}
VALID_ENVS=("dev" "prod")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1Password configuration
OP_VAULT="Personal" # Update this to your 1Password vault name

echo -e "${BLUE}🏠 Homelab Secrets Setup${NC}"
echo -e "${BLUE}========================${NC}"
echo ""

# Validate environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENV} " ]]; then
    echo -e "${RED}✗ Invalid environment: $ENV${NC}"
    echo "Valid environments: ${VALID_ENVS[*]}"
    exit 1
fi

echo -e "${GREEN}✓ Setting up secrets for environment: $ENV${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}→ Checking prerequisites...${NC}"

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl not found. Please install kubectl.${NC}"
        exit 1
    fi

    # Check if op (1Password CLI) is installed
    if ! command -v op &> /dev/null; then
        echo -e "${RED}✗ 1Password CLI not found.${NC}"
        echo "Install with: brew install --cask 1password-cli"
        exit 1
    fi

    # Check if user is signed in to 1Password
    if ! op account list &> /dev/null; then
        echo -e "${YELLOW}→ Not signed in to 1Password. Signing in...${NC}"
        eval $(op signin)
    fi

    echo -e "${GREEN}✓ Prerequisites satisfied${NC}"
}

# Set the appropriate kubectl context
set_context() {
    case $ENV in
        "dev")
            # Use the kubeconfig from terraform output
            # Check from script location
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            KUBECONFIG_PATH="$SCRIPT_DIR/../../terraform/proxmox/environments/dev/kubeconfig"
            if [ -f "$KUBECONFIG_PATH" ]; then
                export KUBECONFIG="$KUBECONFIG_PATH"
                echo -e "${GREEN}✓ Using kubeconfig from: $KUBECONFIG_PATH${NC}"
            else
                echo -e "${RED}✗ Kubeconfig not found at: $KUBECONFIG_PATH${NC}"
                echo "Run terraform in terraform/proxmox/environments/dev first"
                exit 1
            fi
            ;;
        "prod")
            # Use the kubeconfig from terraform output
            # Check from script location
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            KUBECONFIG_PATH="$SCRIPT_DIR/../../terraform/proxmox/environments/prod/kubeconfig"
            if [ -f "$KUBECONFIG_PATH" ]; then
                export KUBECONFIG="$KUBECONFIG_PATH"
                echo -e "${GREEN}✓ Using kubeconfig from: $KUBECONFIG_PATH${NC}"
            else
                echo -e "${RED}✗ Kubeconfig not found at: $KUBECONFIG_PATH${NC}"
                exit 1
            fi
            ;;
    esac

    # Test connection
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✓ Connected to cluster${NC}"
    else
        echo -e "${RED}✗ Cannot connect to cluster${NC}"
        exit 1
    fi
}

# Get secret from 1Password or environment variable
get_secret_value() {
    local secret_name="$1"
    local op_item_name="$2"
    local op_field_name="${3:-password}"
    local env_var_name="$4"

    # Check if environment variable is already set
    if [ -n "$env_var_name" ] && [ -n "${!env_var_name}" ]; then
        echo "${!env_var_name}"
        return
    fi

    # Try to get from 1Password
    local value=$(op item get "$op_item_name" --vault="$OP_VAULT" --fields="$op_field_name" --reveal 2>/dev/null || echo "")

    if [ -z "$value" ]; then
        return 1
    fi

    echo "$value"
}

# Create or update a Kubernetes secret
create_k8s_secret() {
    local namespace="$1"
    local secret_name="$2"
    local secret_key="$3"
    local secret_value="$4"

    echo -e "${YELLOW}→ Creating/updating secret: $secret_name in namespace: $namespace${NC}"

    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    # Create or update the secret
    kubectl create secret generic "$secret_name" \
        --from-literal="$secret_key"="$secret_value" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f - > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Secret $secret_name created/updated successfully${NC}"
    else
        echo -e "${RED}✗ Failed to create/update secret $secret_name${NC}"
        return 1
    fi
}

# Create secret from file
create_k8s_secret_from_file() {
    local namespace="$1"
    local secret_name="$2"
    local secret_key="$3"
    local file_path="$4"

    echo -e "${YELLOW}→ Creating/updating secret: $secret_name in namespace: $namespace${NC}"

    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    # Create or update the secret
    kubectl create secret generic "$secret_name" \
        --from-file="$secret_key"="$file_path" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f - > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Secret $secret_name created/updated successfully${NC}"
    else
        echo -e "${RED}✗ Failed to create/update secret $secret_name${NC}"
        return 1
    fi
}

# Setup Cloudflare Tunnel secret
setup_cloudflare_tunnel_secret() {
    echo ""
    echo -e "${BLUE}🚇 Setting up Cloudflare Tunnel secret...${NC}"

    # Create cloudflare namespace if it doesn't exist
    echo -e "${YELLOW}→ Ensuring cloudflare namespace exists...${NC}"
    kubectl create namespace cloudflare --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    # First try environment variable
    if [ -n "${CLOUDFLARE_TUNNEL_CREDENTIALS_JSON:-}" ]; then
        echo -e "${YELLOW}→ Using Cloudflare credentials from environment variable${NC}"
        echo "$CLOUDFLARE_TUNNEL_CREDENTIALS_JSON" | kubectl create secret generic cloudflared-credentials \
            --namespace=cloudflare \
            --from-file=credentials.json=/dev/stdin \
            --dry-run=client -o yaml | kubectl apply -f - > /dev/null
        echo -e "${GREEN}✓ Cloudflare Tunnel secret created from environment variable${NC}"
    # Then try 1Password
    elif op item get "Cloudflare Tunnel - Homelab" --vault="$OP_VAULT" &> /dev/null; then
        local credentials=$(op item get "Cloudflare Tunnel - Homelab" --vault="$OP_VAULT" --fields="credential" --reveal 2>/dev/null || echo "")

        if [ -n "$credentials" ]; then
            echo "$credentials" | kubectl create secret generic cloudflared-credentials \
                --namespace=cloudflare \
                --from-file=credentials.json=/dev/stdin \
                --dry-run=client -o yaml | kubectl apply -f - > /dev/null
            echo -e "${GREEN}✓ Cloudflare Tunnel secret created from 1Password${NC}"
        else
            echo -e "${YELLOW}⚠ Cloudflare Tunnel credentials field not found in 1Password item${NC}"
            echo -e "${YELLOW}   Ensure the item has a field named 'credentials' with the JSON content${NC}"
        fi
    # Finally try local file
    elif [ -f "$HOME/.cloudflared/credentials.json" ]; then
        echo -e "${YELLOW}→ Using Cloudflare credentials from local file${NC}"
        create_k8s_secret_from_file "cloudflare" "cloudflared-credentials" "credentials.json" "$HOME/.cloudflared/credentials.json"
    else
        echo -e "${YELLOW}⚠ Cloudflare Tunnel credentials not found. Skipping...${NC}"
        echo -e "${YELLOW}   To enable, add 'Cloudflare Tunnel - Homelab' to 1Password vault '$OP_VAULT'${NC}"
        echo -e "${YELLOW}   Or set CLOUDFLARE_TUNNEL_CREDENTIALS_JSON environment variable${NC}"
    fi
}


# Setup N8N secrets
setup_n8n_secrets() {
    echo ""
    echo -e "${BLUE}🔧 Setting up N8N secrets...${NC}"

    # Get encryption key from 1Password or generate
    local encryption_key=$(get_secret_value \
        "N8N encryption key" \
        "N8N Homelab [$ENV]" \
        "encryption_key" \
        "N8N_ENCRYPTION_KEY")

    if [ -z "$encryption_key" ]; then
        echo -e "${YELLOW}→ Generating new N8N encryption key...${NC}"
        encryption_key=$(openssl rand -base64 32)
        echo -e "${YELLOW}   Save this key to 1Password: $encryption_key${NC}"
    fi

    create_k8s_secret "n8n" "n8n-secrets" "N8N_ENCRYPTION_KEY" "$encryption_key"

    # Optional: N8N webhook URL
    local webhook_url=$(get_secret_value \
        "N8N webhook URL" \
        "N8N Homelab [$ENV]" \
        "webhook_url" \
        "N8N_WEBHOOK_URL")

    if [ -n "$webhook_url" ]; then
        kubectl patch secret n8n-secrets -n n8n --type='json' \
            -p='[{"op": "add", "path": "/data/WEBHOOK_URL", "value": "'$(echo -n "$webhook_url" | base64)'"}]' 2>/dev/null || true
    fi
}


# Environment-specific secret setup
setup_environment_secrets() {
    case $ENV in
        "dev")
            echo -e "${BLUE}🔧 Setting up development environment secrets...${NC}"
            # Dev-specific secrets
            ;;
        "prod")
            echo -e "${BLUE}🚀 Setting up production environment secrets...${NC}"
            # Production-specific secrets with extra validation
            echo -e "${YELLOW}⚠ Production environment - ensure secrets are production-ready${NC}"
            ;;
    esac
}

# Show secret status
show_secret_status() {
    echo ""
    echo -e "${BLUE}📊 Secret Status${NC}"
    echo -e "${BLUE}===============${NC}"
    echo ""

    echo -e "${YELLOW}Cloudflare Secrets:${NC}"
    kubectl get secrets -n cloudflare 2>/dev/null | grep -E "(cloudflare|tunnel)" || echo "  No Cloudflare secrets found"

    echo ""
    echo -e "${YELLOW}Application Secrets:${NC}"
    kubectl get secrets -n n8n 2>/dev/null | grep -E "(n8n)" || echo "  No N8N secrets found"

}

# Main execution
main() {
    check_prerequisites
    set_context
    setup_environment_secrets

    # Setup all secrets
    setup_cloudflare_tunnel_secret
    setup_n8n_secrets

    # Show final status
    show_secret_status

    echo ""
    echo -e "${GREEN}✓ Secret setup completed for $ENV environment!${NC}"
    echo ""
    echo -e "${BLUE}📝 Next steps:${NC}"
    echo "   1. Deploy ArgoCD: ./kubernetes/bootstrap/argocd.sh $ENV"
    echo "   2. Monitor sync: kubectl get apps -n argocd -w"
    echo "   3. Access services via Cloudflare Tunnel"
    echo ""
    echo -e "${YELLOW}💡 To add more secrets:${NC}"
    echo "   1. Add items to 1Password vault: $OP_VAULT"
    echo "   2. Update this script with new secret mappings"
    echo "   3. Run: $0 $ENV"
}

# Handle different command line options
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [dev|prod]"
        echo ""
        echo "Setup Kubernetes secrets from 1Password"
        echo ""
        echo "This script:"
        echo "  - Checks for existing environment variables first"
        echo "  - Falls back to 1Password if variables not set"
        echo "  - Creates appropriate Kubernetes secrets"
        echo "  - Handles environment-specific configurations"
        echo ""
        echo "Required 1Password items:"
        echo "  - 'Cloudflare Tunnel - Homelab' (tunnel credentials)"
        echo "  - 'N8N Homelab [DEV/PROD]' (N8N configuration)"
        echo ""
        echo "Environment variables (optional):"
        echo "  - CLOUDFLARE_TUNNEL_CREDENTIALS_JSON"
        echo "  - N8N_ENCRYPTION_KEY"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
