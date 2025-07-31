#!/bin/bash
# Bootstrap ArgoCD for homelab
# Simple script to install ArgoCD and create the app-of-apps

set -euo pipefail

# Configuration
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.11.3}"
ARGOCD_NAMESPACE="argocd"
REPO_URL="https://github.com/TechDufus/home.io"
REPO_BRANCH="${REPO_BRANCH:-main}"
ENVIRONMENT="${1:-dev}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show banner
echo -e "${BLUE}🚀 ArgoCD Bootstrap for Homelab${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi
    
    log_info "Prerequisites satisfied"
}

# Create namespace
create_namespace() {
    log_info "Creating ArgoCD namespace..."
    kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
}

# Install ArgoCD
install_argocd() {
    log_info "Installing ArgoCD ${ARGOCD_VERSION}..."
    kubectl apply -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml
    
    log_info "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n ${ARGOCD_NAMESPACE}
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n ${ARGOCD_NAMESPACE}
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-redis -n ${ARGOCD_NAMESPACE}
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-applicationset-controller -n ${ARGOCD_NAMESPACE}
    
    log_info "ArgoCD installed successfully"
}

# Configure ArgoCD for insecure mode (since we're using Cloudflare Tunnel)
configure_argocd() {
    log_info "Configuring ArgoCD..."
    
    # Patch ArgoCD to run in insecure mode
    kubectl patch configmap argocd-cmd-params-cm -n ${ARGOCD_NAMESPACE} --type merge -p '{"data":{"server.insecure":"true"}}'
    
    # Restart ArgoCD server to apply changes
    kubectl rollout restart deployment argocd-server -n ${ARGOCD_NAMESPACE}
    kubectl rollout status deployment argocd-server -n ${ARGOCD_NAMESPACE}
    
    log_info "ArgoCD configured"
}

# Create the bootstrap application
create_bootstrap_app() {
    log_info "Creating app-of-apps..."
    
    # Apply the app-of-apps directly
    kubectl apply -f https://raw.githubusercontent.com/TechDufus/home.io/${REPO_BRANCH}/kubernetes/argocd-apps/app-of-apps.yaml
    
    log_info "App-of-apps created"
}

# Get admin password
get_admin_password() {
    log_info "Retrieving admin password..."
    
    # Wait for secret to be created
    while ! kubectl get secret argocd-initial-admin-secret -n ${ARGOCD_NAMESPACE} &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    
    ADMIN_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}ArgoCD Admin Credentials:${NC}"
    echo -e "${GREEN}Username: admin${NC}"
    echo -e "${GREEN}Password: ${ADMIN_PASSWORD}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Print access instructions
print_access_info() {
    echo -e "${BLUE}📋 Access Instructions${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo ""
    echo "1. Port Forward (temporary access):"
    echo "   kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:80"
    echo "   Open: http://localhost:8080"
    echo ""
    echo "2. Via Cloudflare Tunnel (after cloudflared is deployed):"
    echo "   https://argocd.home.techdufus.com"
    echo ""
    echo "3. Check application status:"
    echo "   kubectl get applications -n ${ARGOCD_NAMESPACE}"
    echo ""
    echo "4. View logs:"
    echo "   kubectl logs -n ${ARGOCD_NAMESPACE} deployment/argocd-server"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    create_namespace
    install_argocd
    configure_argocd
    create_bootstrap_app
    get_admin_password
    print_access_info
    
    echo -e "${GREEN}✅ ArgoCD bootstrap completed!${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Apps will start syncing automatically...${NC}"
    echo "   Watch progress: kubectl get apps -n ${ARGOCD_NAMESPACE} -w"
}

# Show help
show_help() {
    echo "Usage: $0 [environment]"
    echo ""
    echo "Bootstrap ArgoCD in your Kubernetes cluster"
    echo ""
    echo "Arguments:"
    echo "  environment    The environment to deploy (default: dev)"
    echo ""
    echo "Environment variables:"
    echo "  ARGOCD_VERSION    ArgoCD version to install (default: v2.11.3)"
    echo "  REPO_BRANCH       Git branch to track (default: main)"
    echo ""
    echo "Examples:"
    echo "  $0              # Install for dev environment"
    echo "  $0 prod         # Install for prod environment"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main
        ;;
esac