#!/bin/bash
set -euo pipefail

# Setup script for external access via Cloudflare Tunnel
# This script helps configure external access to home lab services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl first."
    fi
    
    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Unable to connect to Kubernetes cluster. Check your kubeconfig."
    fi
    
    # Check if ArgoCD is running
    if ! kubectl get namespace argocd &> /dev/null; then
        log_error "ArgoCD namespace not found. Please deploy Kubernetes cluster first."
    fi
    
    log_info "Prerequisites check completed."
}

setup_cloudflare_tunnel() {
    log_step "Setting up Cloudflare Tunnel..."
    
    echo "You need to:"
    echo "1. Go to https://one.dash.cloudflare.com/"
    echo "2. Navigate to Access → Tunnels"
    echo "3. Create a tunnel named 'techdufus-home-lab'"
    echo "4. Copy the tunnel token"
    echo ""
    
    read -p "Have you created the tunnel and copied the token? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_error "Please create the Cloudflare tunnel first, then run this script again."
    fi
    
    echo ""
    read -p "Enter your tunnel token: " -r TUNNEL_TOKEN
    
    if [[ -z "$TUNNEL_TOKEN" ]]; then
        log_error "Tunnel token cannot be empty."
    fi
    
    # Base64 encode the token
    ENCODED_TOKEN=$(echo -n "$TUNNEL_TOKEN" | base64)
    
    # Update the secret file
    log_info "Updating tunnel token in secret file..."
    sed -i.bak "s/token: \".*\"/token: \"$ENCODED_TOKEN\"/" \
        "$PROJECT_ROOT/kubernetes/infrastructure/cloudflare-tunnel/secret.yaml"
    
    log_info "Tunnel token updated successfully."
}

update_tunnel_config() {
    log_step "Updating tunnel configuration..."
    
    local config_file="$PROJECT_ROOT/kubernetes/infrastructure/cloudflare-tunnel/configmap.yaml"
    
    echo "Current services configured for external access:"
    echo "- argocd.lab.techdufus.com → ArgoCD"
    echo "- ha.lab.techdufus.com → Home Assistant"
    echo ""
    
    read -p "Do you want to add more services? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        echo "Edit the file: $config_file"
        echo "Add new hostname entries in the ingress section"
        read -p "Press Enter when you're done editing..."
    fi
}

setup_dns_records() {
    log_step "Setting up DNS records..."
    
    echo "You need to configure DNS records in Cloudflare:"
    echo ""
    echo "1. Go to your Cloudflare dashboard for techdufus.com"
    echo "2. Go to DNS → Records"
    echo "3. The tunnel should automatically create CNAME records, but verify:"
    echo "   - argocd.lab.techdufus.com → <tunnel-id>.cfargotunnel.com"
    echo "   - ha.lab.techdufus.com → <tunnel-id>.cfargotunnel.com"
    echo ""
    echo "4. Set SSL/TLS mode to 'Full (strict)'"
    echo "5. Enable 'Always Use HTTPS'"
    echo ""
    
    read -p "Have you configured the DNS records? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_warn "Please configure DNS records before proceeding."
    fi
}

deploy_tunnel() {
    log_step "Deploying Cloudflare Tunnel to Kubernetes..."
    
    # Apply the tunnel configuration directly
    kubectl apply -f "$PROJECT_ROOT/kubernetes/infrastructure/cloudflare-tunnel/"
    
    # Wait for deployment to be ready
    log_info "Waiting for tunnel deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/cloudflare-tunnel -n cloudflare-tunnel
    
    # Check tunnel status
    log_info "Checking tunnel status..."
    kubectl get pods -n cloudflare-tunnel
    kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel --tail=10
}

test_connectivity() {
    log_step "Testing connectivity..."
    
    # Test internal access
    log_info "Testing internal access..."
    if kubectl get ingress argocd-server -n argocd &> /dev/null; then
        log_info "✓ ArgoCD ingress found"
    else
        log_warn "✗ ArgoCD ingress not found"
    fi
    
    # Get external IPs for testing
    echo ""
    echo "Test these URLs:"
    echo "- Internal ArgoCD: https://argocd.home.io"
    echo "- External ArgoCD: https://argocd.lab.techdufus.com"
    echo "- External Home Assistant: https://ha.lab.techdufus.com"
    echo ""
    
    read -p "Test the URLs above and press Enter when done..."
}

deploy_via_argocd() {
    log_step "Deploying via ArgoCD (recommended)..."
    
    echo "Instead of applying directly, you can:"
    echo "1. Commit your changes to git"
    echo "2. Push to your repository"
    echo "3. ArgoCD will automatically sync the changes"
    echo ""
    
    read -p "Do you want to commit and push changes? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        cd "$PROJECT_ROOT"
        
        # Check if there are changes to commit
        if [[ -n $(git status --porcelain) ]]; then
            git add kubernetes/infrastructure/cloudflare-tunnel/
            git commit -m "feat: add Cloudflare Tunnel for external access

- Configure tunnel for argocd.lab.techdufus.com and ha.lab.techdufus.com
- Add dual-domain ingress support
- Enable secure external access with automatic SSL"
            
            echo "Changes committed. Push with:"
            echo "git push origin main"
        else
            log_info "No changes to commit."
        fi
    fi
}

show_next_steps() {
    log_step "Next Steps"
    
    echo ""
    echo "🎉 Cloudflare Tunnel setup is complete!"
    echo ""
    echo "Next steps:"
    echo "1. Monitor tunnel status: kubectl logs -n cloudflare-tunnel -l app=cloudflare-tunnel -f"
    echo "2. Test external access to your services"
    echo "3. Configure additional security in Cloudflare dashboard"
    echo "4. Add more services by updating the tunnel configuration"
    echo ""
    echo "Security recommendations:"
    echo "- Enable Cloudflare Access policies for sensitive services"
    echo "- Configure WAF rules for additional protection"
    echo "- Monitor access logs regularly"
    echo ""
    echo "Documentation: docs/external-access-setup.md"
}

main() {
    echo "==================================="
    echo "Cloudflare Tunnel Setup Script"
    echo "==================================="
    echo ""
    
    check_prerequisites
    
    # Step 1: Cloudflare setup
    read -p "Step 1: Setup Cloudflare Tunnel? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        setup_cloudflare_tunnel
        update_tunnel_config
        setup_dns_records
    fi
    
    # Step 2: Deploy to Kubernetes
    read -p "Step 2: Deploy tunnel to Kubernetes? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        echo "Choose deployment method:"
        echo "1. Deploy directly with kubectl"
        echo "2. Deploy via ArgoCD (recommended)"
        read -p "Enter choice (1 or 2): " -r DEPLOY_METHOD
        
        case $DEPLOY_METHOD in
            1)
                deploy_tunnel
                ;;
            2)
                deploy_via_argocd
                ;;
            *)
                log_error "Invalid choice. Please run the script again."
                ;;
        esac
    fi
    
    # Step 3: Test
    read -p "Step 3: Test connectivity? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        test_connectivity
    fi
    
    show_next_steps
}

# Run main function
main "$@"