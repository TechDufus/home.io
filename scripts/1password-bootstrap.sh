#!/bin/bash
set -euo pipefail

# 1Password Bootstrap Script for CAPI Clusters
# This script securely retrieves secrets from 1Password and sets up cluster infrastructure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
OP_VAULT="cicd"
OP_SERVICE_ACCOUNT_TOKEN_ENV="OP_SERVICE_ACCOUNT_TOKEN"
CLUSTER_NAME=""
ENVIRONMENT=""
DRY_RUN=false
VALIDATE_ONLY=false

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Bootstrap CAPI cluster with 1Password secret management.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster (required)
    -e, --env ENVIRONMENT       Environment: dev, prod (required)
    -v, --vault VAULT_NAME      1Password vault name (default: cicd)
    --dry-run                   Show what would be done without executing
    --validate-only             Only validate 1Password access and secrets
    --help                      Show this help message

ENVIRONMENT VARIABLES:
    OP_SERVICE_ACCOUNT_TOKEN    1Password service account token (required)

EXAMPLES:
    # Bootstrap dev cluster
    export OP_SERVICE_ACCOUNT_TOKEN="ops_..."
    $0 --name dev --env dev

    # Validate secrets without creating cluster
    $0 --name prod --env prod --validate-only

    # Dry run to see what would be executed
    $0 --name prod --env prod --dry-run

PREREQUISITES:
    - 1Password CLI (op) installed and in PATH
    - Service account token with access to cicd vault
    - CAPI management cluster available
    - kubectl configured for management cluster
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--vault)
                OP_VAULT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done

    if [[ -z "$CLUSTER_NAME" || -z "$ENVIRONMENT" ]]; then
        log_error "Cluster name and environment are required. Use --name and --env."
    fi

    if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
        log_error "Environment must be one of: dev, prod"
    fi
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check 1Password CLI
    if ! command -v op &> /dev/null; then
        log_error "1Password CLI (op) not found. Install from: https://developer.1password.com/docs/cli/get-started/"
    fi
    
    # Check service account token
    if [[ -z "${!OP_SERVICE_ACCOUNT_TOKEN_ENV:-}" ]]; then
        log_error "1Password service account token not found. Set $OP_SERVICE_ACCOUNT_TOKEN_ENV environment variable."
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
    fi
    
    # Check CAPI CLI
    if ! command -v clusterctl &> /dev/null; then
        log_error "clusterctl not found. Please install CAPI CLI."
    fi
    
    log_info "Prerequisites check completed."
}

authenticate_1password() {
    log_step "Authenticating with 1Password..."
    
    # Set service account token
    export OP_SERVICE_ACCOUNT_TOKEN="${!OP_SERVICE_ACCOUNT_TOKEN_ENV}"
    
    # Validate authentication
    if ! op vault list --format=json &> /dev/null; then
        log_error "1Password authentication failed. Check your service account token."
    fi
    
    # Verify vault access
    if ! op vault get "$OP_VAULT" &> /dev/null; then
        log_error "Cannot access vault '$OP_VAULT'. Check service account permissions."
    fi
    
    log_info "1Password authentication successful."
}

get_secret() {
    local item_path="$1"
    local field="${2:-password}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY_RUN] Would retrieve: $item_path[$field]"
        return 0
    fi
    
    op item get "$item_path" --vault="$OP_VAULT" --field="$field" 2>/dev/null || {
        log_error "Failed to retrieve secret: $item_path[$field]"
    }
}

validate_required_secrets() {
    log_step "Validating required secrets..."
    
    local required_secrets=(
        "Infrastructure/${ENVIRONMENT}-proxmox-api-token:token"
        "Infrastructure/${ENVIRONMENT}-proxmox-api-endpoint:url"
        "Infrastructure/${ENVIRONMENT}-ssh-private-key:private_key"
        "Infrastructure/${ENVIRONMENT}-ssh-public-key:public_key"
        "Service-Accounts/1password-operator-${CLUSTER_NAME}:token"
        "External-Services/${ENVIRONMENT}-cloudflare-dns-token:token"
    )
    
    local missing_secrets=()
    
    for secret_def in "${required_secrets[@]}"; do
        local item_path="${secret_def%:*}"
        local field="${secret_def#*:}"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would validate: $item_path[$field]"
            continue
        fi
        
        if ! op item get "$item_path" --vault="$OP_VAULT" --field="$field" &> /dev/null; then
            missing_secrets+=("$item_path[$field]")
        else
            log_info "✓ Found: $item_path[$field]"
        fi
    done
    
    if [[ ${#missing_secrets[@]} -gt 0 ]]; then
        log_error "Missing required secrets:\n$(printf '  - %s\n' "${missing_secrets[@]}")"
    fi
    
    log_info "All required secrets validated."
}

export_cluster_secrets() {
    log_step "Exporting cluster secrets to environment..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would export cluster secrets to environment variables"
        return 0
    fi
    
    # Proxmox configuration
    export PROXMOX_TOKEN=$(get_secret "Infrastructure/${ENVIRONMENT}-proxmox-api-token" "token")
    export PROXMOX_SECRET=$(get_secret "Infrastructure/${ENVIRONMENT}-proxmox-api-token" "secret")
    export PROXMOX_URL=$(get_secret "Infrastructure/${ENVIRONMENT}-proxmox-api-endpoint" "url")
    
    # SSH keys for VM access
    export SSH_PRIVATE_KEY=$(get_secret "Infrastructure/${ENVIRONMENT}-ssh-private-key" "private_key")
    export SSH_PUBLIC_KEY=$(get_secret "Infrastructure/${ENVIRONMENT}-ssh-public-key" "public_key")
    
    # Cloudflare for DNS management
    export CLOUDFLARE_API_TOKEN=$(get_secret "External-Services/${ENVIRONMENT}-cloudflare-dns-token" "token")
    
    # 1Password operator token for the cluster
    export ONEPASSWORD_OPERATOR_TOKEN=$(get_secret "Service-Accounts/1password-operator-${CLUSTER_NAME}" "token")
    
    log_info "Cluster secrets exported to environment."
}

create_ssh_key_files() {
    log_step "Creating SSH key files..."
    
    local ssh_dir="$HOME/.ssh"
    local private_key_file="$ssh_dir/id_rsa_${CLUSTER_NAME}"
    local public_key_file="$ssh_dir/id_rsa_${CLUSTER_NAME}.pub"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create SSH key files: $private_key_file, $public_key_file"
        return 0
    fi
    
    mkdir -p "$ssh_dir"
    
    # Create private key
    echo "$SSH_PRIVATE_KEY" > "$private_key_file"
    chmod 600 "$private_key_file"
    
    # Create public key
    echo "$SSH_PUBLIC_KEY" > "$public_key_file"
    chmod 644 "$public_key_file"
    
    log_info "SSH key files created: $private_key_file, $public_key_file"
    
    # Export for use by other scripts
    export SSH_PRIVATE_KEY_FILE="$private_key_file"
    export SSH_PUBLIC_KEY_FILE="$public_key_file"
}

deploy_1password_operator() {
    log_step "Deploying 1Password operator to cluster..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would deploy 1Password operator to cluster: $CLUSTER_NAME"
        return 0
    fi
    
    # Check if cluster is ready
    if ! kubectl --kubeconfig="$kubeconfig_file" get nodes &> /dev/null; then
        log_error "Cluster $CLUSTER_NAME is not accessible. Run cluster creation first."
    fi
    
    # Deploy operator namespace and RBAC
    kubectl --kubeconfig="$kubeconfig_file" apply -f "$PROJECT_ROOT/kubernetes/secrets/1password/namespace.yaml"
    kubectl --kubeconfig="$kubeconfig_file" apply -f "$PROJECT_ROOT/kubernetes/secrets/1password/crds.yaml"
    
    # Create operator service account token secret
    kubectl --kubeconfig="$kubeconfig_file" create secret generic onepassword-token \
        --namespace=onepassword-operator \
        --from-literal=token="$ONEPASSWORD_OPERATOR_TOKEN" \
        --dry-run=client -o yaml | kubectl --kubeconfig="$kubeconfig_file" apply -f -
    
    # Deploy operator
    kubectl --kubeconfig="$kubeconfig_file" apply -f "$PROJECT_ROOT/kubernetes/secrets/1password/operator.yaml"
    
    # Wait for operator to be ready
    log_info "Waiting for 1Password operator to be ready..."
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=available \
        --timeout=300s deployment/onepassword-operator -n onepassword-operator
    
    log_info "1Password operator deployed successfully."
}

create_cluster_secrets() {
    log_step "Creating initial cluster secrets..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    local secrets_dir="$PROJECT_ROOT/kubernetes/secrets/secret-references"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create cluster secrets from: $secrets_dir"
        return 0
    fi
    
    # Apply environment-specific secret references
    if [[ -f "$secrets_dir/${ENVIRONMENT}-secrets.yaml" ]]; then
        # Substitute cluster name in secret references
        sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" "$secrets_dir/${ENVIRONMENT}-secrets.yaml" | \
            kubectl --kubeconfig="$kubeconfig_file" apply -f -
        log_info "Applied $ENVIRONMENT environment secrets."
    fi
    
    # Apply cluster-specific secret references if they exist
    if [[ -f "$secrets_dir/${CLUSTER_NAME}-secrets.yaml" ]]; then
        kubectl --kubeconfig="$kubeconfig_file" apply -f "$secrets_dir/${CLUSTER_NAME}-secrets.yaml"
        log_info "Applied $CLUSTER_NAME cluster-specific secrets."
    fi
}

cleanup() {
    log_step "Cleaning up temporary files..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would clean up SSH key files and environment variables"
        return 0
    fi
    
    # Remove SSH key files
    if [[ -n "${SSH_PRIVATE_KEY_FILE:-}" && -f "$SSH_PRIVATE_KEY_FILE" ]]; then
        rm -f "$SSH_PRIVATE_KEY_FILE"
        log_info "Removed private key file: $SSH_PRIVATE_KEY_FILE"
    fi
    
    # Unset sensitive environment variables
    unset PROXMOX_TOKEN PROXMOX_SECRET SSH_PRIVATE_KEY ONEPASSWORD_OPERATOR_TOKEN CLOUDFLARE_API_TOKEN
    
    log_info "Cleanup completed."
}

display_summary() {
    log_step "Bootstrap Summary"
    
    echo ""
    echo "🎉 1Password bootstrap completed successfully!"
    echo ""
    echo "Cluster Details:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Environment: $ENVIRONMENT"
    echo "  Vault: $OP_VAULT"
    echo ""
    echo "Next Steps:"
    echo "1. Create CAPI cluster:"
    echo "   $PROJECT_ROOT/kubernetes/capi/scripts/create-cluster.sh --name $CLUSTER_NAME --env $ENVIRONMENT --install-addons"
    echo ""
    echo "2. Install ArgoCD with 1Password secrets:"
    echo "   $PROJECT_ROOT/kubernetes/capi/scripts/install-argocd.sh --name $CLUSTER_NAME"
    echo ""
    echo "3. Setup external access:"
    echo "   $PROJECT_ROOT/kubernetes/capi/scripts/setup-external-access.sh --name $CLUSTER_NAME"
    echo ""
    echo "Monitoring:"
    echo "  Check 1Password operator: kubectl get pods -n onepassword-operator"
    echo "  View secret references: kubectl get onepassworditems -A"
    echo ""
}

main() {
    echo "==========================================="
    echo "1Password Bootstrap for CAPI Clusters"
    echo "==========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    authenticate_1password
    validate_required_secrets
    
    if [[ "$VALIDATE_ONLY" == "true" ]]; then
        log_info "Validation completed successfully. Secrets are accessible."
        exit 0
    fi
    
    export_cluster_secrets
    create_ssh_key_files
    
    # Deploy operator only if cluster exists
    if kubectl config get-contexts | grep -q "config-${CLUSTER_NAME}"; then
        deploy_1password_operator
        create_cluster_secrets
    else
        log_info "Cluster not found. 1Password operator will be deployed after cluster creation."
    fi
    
    display_summary
    
    # Set trap for cleanup on exit
    trap cleanup EXIT
}

# Run main function
main "$@"