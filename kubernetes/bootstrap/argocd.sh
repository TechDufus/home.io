#!/bin/bash
# Bootstrap ArgoCD for k3s homelab cluster
# Installs ArgoCD via Helm and deploys the app-of-apps

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_NAMESPACE="argocd"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}ArgoCD Bootstrap for k3s Homelab${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        log_error "helm not found. Please install helm."
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        exit 1
    fi

    log_info "Prerequisites satisfied"
}

# Install ArgoCD via Helm
install_argocd() {
    log_info "Adding ArgoCD Helm repository..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update argo

    log_info "Installing ArgoCD via Helm..."
    helm upgrade --install argocd argo/argo-cd \
        --namespace ${ARGOCD_NAMESPACE} \
        --create-namespace \
        -f "${SCRIPT_DIR}/../argocd/values/argocd.yaml" \
        --wait

    log_info "ArgoCD installed successfully"
}

# Deploy the app-of-apps
deploy_app_of_apps() {
    log_info "Deploying app-of-apps..."
    kubectl apply -f "${SCRIPT_DIR}/../argocd/app-of-apps.yaml"
    log_info "App-of-apps deployed"
}

# Get admin password
get_admin_password() {
    log_info "Retrieving admin password..."

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
    echo -e "${BLUE}Access Instructions${NC}"
    echo -e "${BLUE}===================${NC}"
    echo ""
    echo "1. Port Forward (temporary access):"
    echo "   kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:80"
    echo "   Open: http://localhost:8080"
    echo ""
    echo "2. Via Tailscale (after tailscale-operator is deployed):"
    echo "   Access via Tailscale-exposed service once configured"
    echo ""
    echo "3. Check application status:"
    echo "   kubectl get applications -n ${ARGOCD_NAMESPACE}"
    echo ""
    echo "4. Retrieve password later:"
    echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    install_argocd
    deploy_app_of_apps
    get_admin_password
    print_access_info

    echo -e "${GREEN}ArgoCD bootstrap completed!${NC}"
    echo ""
    echo -e "${YELLOW}Apps will start syncing automatically...${NC}"
    echo "   Watch progress: kubectl get apps -n ${ARGOCD_NAMESPACE} -w"
}

# Show help
show_help() {
    echo "Usage: $0"
    echo ""
    echo "Bootstrap ArgoCD in your k3s cluster via Helm"
    echo ""
    echo "This script:"
    echo "  - Installs ArgoCD via Helm chart with custom values"
    echo "  - Deploys the app-of-apps for GitOps management"
    echo "  - Prints admin credentials and access instructions"
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
