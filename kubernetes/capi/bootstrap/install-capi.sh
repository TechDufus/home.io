#!/bin/bash
set -euo pipefail

# CAPI Bootstrap Installation Script
# This script sets up the management cluster and installs Cluster API components

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Tool versions
KIND_VERSION="v0.20.0"
CLUSTERCTL_VERSION="v1.6.1"
KUBECTL_VERSION="v1.29.0"

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
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Please install Docker first."
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker."
    fi
    
    log_info "Prerequisites check completed."
}

install_tools() {
    log_step "Installing required tools..."
    
    # Install kind
    if ! command -v kind &> /dev/null; then
        log_info "Installing kind ${KIND_VERSION}..."
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-$(uname)-amd64"
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    else
        log_info "kind already installed: $(kind version)"
    fi
    
    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        log_info "Installing kubectl ${KUBECTL_VERSION}..."
        curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/$(uname | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/kubectl
    else
        log_info "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'kubectl present')"
    fi
    
    # Install clusterctl
    if ! command -v clusterctl &> /dev/null; then
        log_info "Installing clusterctl ${CLUSTERCTL_VERSION}..."
        curl -L "https://github.com/kubernetes-sigs/cluster-api/releases/download/${CLUSTERCTL_VERSION}/clusterctl-$(uname | tr '[:upper:]' '[:lower:]')-amd64" -o clusterctl
        chmod +x clusterctl
        sudo mv clusterctl /usr/local/bin/clusterctl
    else
        log_info "clusterctl already installed: $(clusterctl version)"
    fi
    
    log_info "All tools installed successfully."
}

create_management_cluster() {
    log_step "Creating Kind management cluster..."
    
    # Check if cluster already exists
    if kind get clusters | grep -q "capi-management"; then
        log_warn "Management cluster already exists. Deleting and recreating..."
        kind delete cluster --name capi-management
    fi
    
    # Create the cluster
    kind create cluster --config="$SCRIPT_DIR/kind-cluster.yaml" --name=capi-management
    
    # Wait for cluster to be ready
    log_info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=ready nodes --all --timeout=300s
    
    log_info "Management cluster created successfully."
}

install_capi_components() {
    log_step "Installing Cluster API components..."
    
    # Set environment variables for clusterctl
    export CLUSTER_TOPOLOGY=true
    export EXP_RUNTIME_SDK=true
    export EXP_MACHINE_POOL=true
    
    # Initialize CAPI
    clusterctl init \
        --infrastructure proxmox \
        --bootstrap kubeadm \
        --control-plane kubeadm \
        --core cluster-api \
        --wait-providers
    
    # Wait for all CAPI components to be ready
    log_info "Waiting for CAPI components to be ready..."
    kubectl wait --for=condition=Available deployments --all -n capi-system --timeout=300s
    kubectl wait --for=condition=Available deployments --all -n capi-kubeadm-bootstrap-system --timeout=300s
    kubectl wait --for=condition=Available deployments --all -n capi-kubeadm-control-plane-system --timeout=300s
    kubectl wait --for=condition=Available deployments --all -n capmox-system --timeout=300s
    
    log_info "CAPI components installed successfully."
}

configure_proxmox_credentials() {
    log_step "Configuring Proxmox credentials..."
    
    # Check if credentials exist
    if kubectl get secret proxmox-credentials -n capmox-system &> /dev/null; then
        log_warn "Proxmox credentials already exist."
        return
    fi
    
    echo "Please provide your Proxmox credentials:"
    read -p "Proxmox API URL (e.g., https://proxmox.home.io:8006/api2/json): " PROXMOX_URL
    read -p "Proxmox Username (e.g., root@pam): " PROXMOX_USERNAME
    read -s -p "Proxmox Password: " PROXMOX_PASSWORD
    echo
    
    # Create credentials secret
    kubectl create secret generic proxmox-credentials \
        --namespace=capmox-system \
        --from-literal=username="$PROXMOX_USERNAME" \
        --from-literal=password="$PROXMOX_PASSWORD"
    
    # Create infrastructure provider configuration
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: proxmox-config
  namespace: capmox-system
data:
  endpoint: "$PROXMOX_URL"
  insecure: "true"  # Set to false if using valid SSL certificates
EOF
    
    log_info "Proxmox credentials configured successfully."
}

install_cni() {
    log_step "Installing CNI (Calico) in management cluster..."
    
    # Install Calico for the management cluster
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
    
    # Wait a moment for the operator to be ready
    sleep 10
    
    # Apply Calico configuration
    cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
EOF
    
    # Wait for Calico to be ready
    kubectl wait --for=condition=Ready pods -l k8s-app=calico-node -n calico-system --timeout=300s
    
    log_info "CNI installed successfully."
}

display_cluster_info() {
    log_step "Cluster Information"
    
    echo ""
    echo "🎉 CAPI Management Cluster Setup Complete!"
    echo ""
    echo "Cluster Details:"
    echo "  Name: capi-management"
    echo "  Context: kind-capi-management"
    echo ""
    echo "CAPI Providers Installed:"
    echo "  Core Provider: cluster-api"
    echo "  Bootstrap Provider: kubeadm"
    echo "  Control Plane Provider: kubeadm"
    echo "  Infrastructure Provider: proxmox"
    echo ""
    echo "Next Steps:"
    echo "1. Verify all components: kubectl get pods -A"
    echo "2. Check CAPI providers: clusterctl describe cluster"
    echo "3. Create your first workload cluster using the provided templates"
    echo ""
    echo "Management cluster kubeconfig is automatically configured."
    echo "Use 'kubectl config use-context kind-capi-management' to switch contexts."
}

cleanup_on_error() {
    if [[ $? -ne 0 ]]; then
        log_error "Setup failed. Cleaning up..."
        kind delete cluster --name capi-management 2>/dev/null || true
    fi
}

main() {
    trap cleanup_on_error ERR
    
    echo "=========================================="
    echo "Cluster API Bootstrap Setup"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    install_tools
    create_management_cluster
    install_cni
    install_capi_components
    configure_proxmox_credentials
    display_cluster_info
    
    log_info "Setup completed successfully!"
}

# Run main function
main "$@"