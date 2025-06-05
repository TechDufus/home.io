#!/bin/bash
set -euo pipefail

# Create Dummy 1Password Secrets for CAPI Bootstrap
# This script creates the minimum required secrets with dummy values

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT="cicd"
ENVIRONMENT="dev"

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

Create dummy 1Password secrets for CAPI cluster bootstrap.

OPTIONS:
    -e, --env ENVIRONMENT       Environment: dev, prod (default: dev)
    -v, --vault VAULT_NAME      1Password vault name (default: cicd)
    --dry-run                   Show what would be created without executing
    -h, --help                  Show this help message

EXAMPLES:
    # Create dev secrets
    $0 --env dev

    # Create prod secrets
    $0 --env prod

    # See what would be created
    $0 --env dev --dry-run

PREREQUISITES:
    - 1Password CLI (op) installed and authenticated
    - Access to create items in the cicd vault
EOF
}

parse_arguments() {
    DRY_RUN=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -v|--vault)
                VAULT="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                ;;
        esac
    done

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
    
    # Check authentication
    if ! op vault list &> /dev/null; then
        log_error "1Password CLI not authenticated. Run 'op signin' first."
    fi
    
    # Check vault access
    if ! op vault get "$VAULT" &> /dev/null; then
        log_error "Cannot access vault '$VAULT'. Check vault name and permissions."
    fi
    
    log_info "Prerequisites check completed."
}

create_secret() {
    local category="$1"
    local title="$2"
    local fields="$3"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY_RUN] Would create: $title"
        return 0
    fi
    
    # Check if item already exists
    if op item get "$title" --vault="$VAULT" &> /dev/null; then
        log_warn "Secret '$title' already exists. Skipping."
        return 0
    fi
    
    # Create the item
    local cmd="op item create --category=\"$category\" --title=\"$title\" --vault=\"$VAULT\""
    
    # Add fields
    IFS=';' read -ra FIELD_ARRAY <<< "$fields"
    for field in "${FIELD_ARRAY[@]}"; do
        cmd="$cmd $field"
    done
    
    if eval "$cmd" &> /dev/null; then
        log_info "✓ Created: $title"
    else
        log_error "Failed to create: $title"
    fi
}

generate_ssh_keys() {
    log_step "Generating temporary SSH key pair..."
    
    local temp_dir="/tmp/capi-ssh-keys"
    local private_key_file="$temp_dir/id_rsa"
    local public_key_file="$temp_dir/id_rsa.pub"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY_RUN] Would generate SSH keys in $temp_dir"
        return 0
    fi
    
    # Create temp directory
    mkdir -p "$temp_dir"
    
    # Generate SSH key pair
    ssh-keygen -t rsa -b 4096 -f "$private_key_file" -N "" -C "capi-${ENVIRONMENT}-dummy-key" &> /dev/null
    
    # Read keys into variables
    SSH_PRIVATE_KEY=$(cat "$private_key_file")
    SSH_PUBLIC_KEY=$(cat "$public_key_file")
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    log_info "SSH key pair generated."
}

create_infrastructure_secrets() {
    log_step "Creating infrastructure secrets..."
    
    # Proxmox API Token
    create_secret "API Credential" \
        "Infrastructure/${ENVIRONMENT}-proxmox-api-token" \
        "token=pvt_dummy_proxmox_token_replace_me;secret=dummy-secret-replace-with-real-value"
    
    # Proxmox API Endpoint
    create_secret "API Credential" \
        "Infrastructure/${ENVIRONMENT}-proxmox-api-endpoint" \
        "url=https://your-proxmox-host.example.com:8006"
    
    # SSH Keys
    if [[ "$DRY_RUN" != "true" ]]; then
        generate_ssh_keys
    fi
    
    create_secret "SSH Key" \
        "Infrastructure/${ENVIRONMENT}-ssh-private-key" \
        "private_key=${SSH_PRIVATE_KEY:-dummy-private-key-content}"
    
    create_secret "SSH Key" \
        "Infrastructure/${ENVIRONMENT}-ssh-public-key" \
        "public_key=${SSH_PUBLIC_KEY:-ssh-rsa dummy-public-key-content user@host}"
}

create_service_account_secrets() {
    log_step "Creating service account secrets..."
    
    # 1Password Operator Token
    create_secret "API Credential" \
        "Service-Accounts/1password-operator-${ENVIRONMENT}" \
        "token=ops_dummy_service_account_token_replace_me"
}

create_external_service_secrets() {
    log_step "Creating external service secrets..."
    
    # Cloudflare DNS Token (optional but recommended)
    create_secret "API Credential" \
        "External-Services/${ENVIRONMENT}-cloudflare-dns-token" \
        "token=dummy_cloudflare_api_token_replace_me"
}

display_summary() {
    log_step "Secret Creation Summary"
    
    echo ""
    echo "🎉 Dummy secrets created for $ENVIRONMENT environment!"
    echo ""
    echo "Vault: $VAULT"
    echo "Environment: $ENVIRONMENT"
    echo ""
    echo "📝 IMPORTANT: These are dummy values that MUST be updated with real credentials:"
    echo ""
    echo "1. Infrastructure/dev-proxmox-api-token"
    echo "   - Replace 'pvt_dummy_proxmox_token_replace_me' with your real Proxmox API token"
    echo "   - Replace 'dummy-secret-replace-with-real-value' with your real Proxmox API secret"
    echo ""
    echo "2. Infrastructure/dev-proxmox-api-endpoint"
    echo "   - Replace 'https://your-proxmox-host.example.com:8006' with your real Proxmox URL"
    echo ""
    echo "3. Infrastructure/dev-ssh-private-key & Infrastructure/dev-ssh-public-key"
    if [[ "$DRY_RUN" != "true" ]]; then
        echo "   - Real SSH keys generated and stored"
        echo "   - You can replace with your preferred SSH keys if desired"
    else
        echo "   - Replace with your real SSH key pair"
    fi
    echo ""
    echo "4. Service-Accounts/1password-operator-dev"
    echo "   - Replace 'ops_dummy_service_account_token_replace_me' with a real 1Password service account token"
    echo "   - This token needs read access to the cicd vault"
    echo ""
    echo "5. External-Services/dev-cloudflare-dns-token"
    echo "   - Replace 'dummy_cloudflare_api_token_replace_me' with your real Cloudflare API token"
    echo "   - This is optional but needed for automatic DNS and certificates"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Update all dummy values with real credentials in 1Password"
    echo "2. Create a 1Password service account for bootstrap access"
    echo "3. Export OP_SERVICE_ACCOUNT_TOKEN with your bootstrap token"
    echo "4. Run: ./scripts/1password-bootstrap.sh --name dev --env dev --validate-only"
    echo "5. If validation passes: ./scripts/1password-bootstrap.sh --name dev --env dev"
    echo ""
    echo "💡 Pro tip: Start with just the Proxmox credentials to get basic cluster creation working,"
    echo "   then add other services incrementally."
}

main() {
    echo "============================================"
    echo "1Password Dummy Secret Creation for CAPI"
    echo "============================================"
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No secrets will be created"
        echo ""
    fi
    
    create_infrastructure_secrets
    create_service_account_secrets
    create_external_service_secrets
    display_summary
    
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "Dummy secret creation completed successfully!"
    else
        log_info "Dry run completed. Run without --dry-run to create secrets."
    fi
}

# Run main function
main "$@"