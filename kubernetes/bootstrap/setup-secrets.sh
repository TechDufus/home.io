#!/bin/bash
# Setup Kubernetes secrets from 1Password
# This script creates required secrets for the k3s homelab cluster
# Usage: ./setup-secrets.sh [dev|prod]

set -euo pipefail

ENV=${1:-dev}
VALID_ENVS=("dev" "prod")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1Password configuration
OP_VAULT="Personal"

echo -e "${BLUE}Homelab Secrets Setup${NC}"
echo -e "${BLUE}=====================${NC}"
echo ""

# Validate environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENV} " ]]; then
    echo -e "${RED}Invalid environment: $ENV${NC}"
    echo "Valid environments: ${VALID_ENVS[*]}"
    exit 1
fi

echo -e "${GREEN}Setting up secrets for environment: $ENV${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl not found. Please install kubectl.${NC}"
        exit 1
    fi

    if ! command -v op &> /dev/null; then
        echo -e "${RED}1Password CLI not found.${NC}"
        echo "Install with: brew install --cask 1password-cli"
        exit 1
    fi

    if ! op account list &> /dev/null; then
        echo -e "${YELLOW}Not signed in to 1Password. Signing in...${NC}"
        eval $(op signin)
    fi

    echo -e "${GREEN}Prerequisites satisfied${NC}"
}

# Set the appropriate kubectl context
set_context() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KUBECONFIG_PATH="$SCRIPT_DIR/../../terraform/proxmox/environments/${ENV}/kubeconfig"

    if [ -f "$KUBECONFIG_PATH" ]; then
        export KUBECONFIG="$KUBECONFIG_PATH"
        echo -e "${GREEN}Using kubeconfig from: $KUBECONFIG_PATH${NC}"
    else
        echo -e "${RED}Kubeconfig not found at: $KUBECONFIG_PATH${NC}"
        echo "Run terraform in terraform/proxmox/environments/$ENV first"
        exit 1
    fi

    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}Connected to cluster${NC}"
    else
        echo -e "${RED}Cannot connect to cluster${NC}"
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
    shift 2

    echo -e "${YELLOW}Creating/updating secret: $secret_name in namespace: $namespace${NC}"

    # Create namespace if it doesn't exist
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    # Build --from-literal args from remaining positional pairs
    local args=()
    while [ $# -ge 2 ]; do
        args+=("--from-literal=$1=$2")
        shift 2
    done

    # Create or update the secret
    kubectl create secret generic "$secret_name" \
        "${args[@]}" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | kubectl apply -f - > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Secret $secret_name created/updated successfully${NC}"
    else
        echo -e "${RED}Failed to create/update secret $secret_name${NC}"
        return 1
    fi
}

# Setup Tailscale Operator OAuth secret
setup_tailscale_secrets() {
    echo ""
    echo -e "${BLUE}Setting up Tailscale Operator secrets...${NC}"

    # Create namespace if it doesn't exist
    kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    local client_id=$(op item get "tailscale-operator-oauth" --vault="$OP_VAULT" --fields="client_id" --reveal 2>/dev/null || \
                      op item get "tailscale-operator-oauth" --vault="$OP_VAULT" --fields="username" --reveal 2>/dev/null || echo "")

    if [ -z "$client_id" ]; then
        echo -e "${RED}Tailscale OAuth client_id not found in 1Password${NC}"
        echo -e "${YELLOW}  Create item 'tailscale-operator-oauth' in vault '$OP_VAULT'${NC}"
        echo -e "${YELLOW}  with fields 'client_id' and 'client_secret'${NC}"
        echo -e "${YELLOW}  Generate at: https://login.tailscale.com/admin/settings/oauth${NC}"
        return 1
    fi

    local client_secret=$(op item get "tailscale-operator-oauth" --vault="$OP_VAULT" --fields="client_secret" --reveal 2>/dev/null || \
                          op item get "tailscale-operator-oauth" --vault="$OP_VAULT" --fields="credential" --reveal 2>/dev/null || \
                          op item get "tailscale-operator-oauth" --vault="$OP_VAULT" --fields="password" --reveal 2>/dev/null || echo "")

    if [ -z "$client_secret" ]; then
        echo -e "${RED}Tailscale OAuth client_secret not found in 1Password${NC}"
        return 1
    fi

    echo -e "${GREEN}Found Tailscale OAuth credentials in 1Password${NC}"
    create_k8s_secret "tailscale" "operator-oauth" \
        "client_id" "$client_id" \
        "client_secret" "$client_secret"
}

# Setup Immich Postgres secret
setup_immich_secrets() {
    echo ""
    echo -e "${BLUE}Setting up Immich Postgres secrets...${NC}"

    # Create namespace if it doesn't exist
    kubectl create namespace immich --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    local password=$(op item get "immich-postgres-password" --vault="$OP_VAULT" --fields="password" --reveal 2>/dev/null || echo "")

    if [ -z "$password" ]; then
        echo -e "${RED}Immich Postgres password not found in 1Password${NC}"
        echo -e "${YELLOW}  Create item 'immich-postgres-password' in vault '$OP_VAULT'${NC}"
        echo -e "${YELLOW}  with field 'password'${NC}"
        return 1
    fi

    echo -e "${GREEN}Found Immich Postgres password in 1Password${NC}"
    create_k8s_secret "immich" "immich-postgres-secret" \
        "POSTGRES_PASSWORD" "$password" \
        "DB_PASSWORD" "$password"
}

# Setup Homepage widget secrets
setup_homepage_secrets() {
    echo ""
    echo -e "${BLUE}Setting up Homepage dashboard secrets...${NC}"

    kubectl create namespace homepage --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

    local proxmox_url=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="proxmox-url" --reveal 2>/dev/null || echo "")
    local proxmox_token_id=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="proxmox-token-id" --reveal 2>/dev/null || echo "")
    local proxmox_token_secret=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="proxmox-token-secret" --reveal 2>/dev/null || echo "")
    local argocd_key=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="argocd-key" --reveal 2>/dev/null || echo "")
    local ha_url=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="ha-url" --reveal 2>/dev/null || echo "")
    local ha_token=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="ha-token" --reveal 2>/dev/null || echo "")
    local immich_key=$(op item get "homepage-secrets" --vault="$OP_VAULT" --fields="immich-key" --reveal 2>/dev/null || echo "")

    if [ -z "$proxmox_url" ]; then
        echo -e "${RED}Homepage secrets not found in 1Password${NC}"
        echo -e "${YELLOW}  Create item 'homepage-secrets' in vault '$OP_VAULT'${NC}"
        echo -e "${YELLOW}  with fields: proxmox-url, proxmox-token-id, proxmox-token-secret,${NC}"
        echo -e "${YELLOW}               argocd-key, ha-url, ha-token, immich-key${NC}"
        return 1
    fi

    echo -e "${GREEN}Found Homepage secrets in 1Password${NC}"
    create_k8s_secret "homepage" "homepage-secrets" \
        "HOMEPAGE_VAR_PROXMOX_URL" "$proxmox_url" \
        "HOMEPAGE_VAR_PROXMOX_TOKEN_ID" "$proxmox_token_id" \
        "HOMEPAGE_VAR_PROXMOX_TOKEN_SECRET" "$proxmox_token_secret" \
        "HOMEPAGE_VAR_ARGOCD_KEY" "$argocd_key" \
        "HOMEPAGE_VAR_HA_URL" "$ha_url" \
        "HOMEPAGE_VAR_HA_TOKEN" "$ha_token" \
        "HOMEPAGE_VAR_IMMICH_KEY" "$immich_key"
}

# Show secret status
show_secret_status() {
    echo ""
    echo -e "${BLUE}Secret Status${NC}"
    echo -e "${BLUE}=============${NC}"
    echo ""

    echo -e "${YELLOW}Tailscale:${NC}"
    kubectl get secrets -n tailscale 2>/dev/null | grep -E "operator-oauth" || echo "  No Tailscale secrets found"

    echo ""
    echo -e "${YELLOW}Immich:${NC}"
    kubectl get secrets -n immich 2>/dev/null | grep -E "immich-postgres-secret" || echo "  No Immich secrets found"

    echo ""
    echo -e "${YELLOW}Homepage:${NC}"
    kubectl get secrets -n homepage 2>/dev/null | grep -E "homepage-secrets" || echo "  No Homepage secrets found"
}

# Main execution
main() {
    check_prerequisites
    set_context

    setup_tailscale_secrets
    setup_immich_secrets
    setup_homepage_secrets

    show_secret_status

    echo ""
    echo -e "${GREEN}Secret setup completed for $ENV environment!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "   1. Deploy ArgoCD: ./kubernetes/bootstrap/argocd.sh $ENV"
    echo "   2. Monitor sync: kubectl get apps -n argocd -w"
}

# Handle different command line options
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [dev|prod]"
        echo ""
        echo "Setup Kubernetes secrets from 1Password for the k3s homelab cluster."
        echo ""
        echo "Required 1Password items:"
        echo "  - 'tailscale-operator-oauth' with fields 'client_id' and 'client_secret'"
        echo "  - 'immich-postgres-password' with field 'password'"
        echo "  - 'homepage-secrets' with fields: proxmox-url, proxmox-token-id,"
        echo "    proxmox-token-secret, argocd-key, ha-url, ha-token, immich-key"
        echo ""
        echo "Both items should be in the '$OP_VAULT' vault."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
