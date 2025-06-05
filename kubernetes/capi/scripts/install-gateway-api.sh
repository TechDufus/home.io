#!/bin/bash
set -euo pipefail

# Gateway API Installation Script for CAPI Clusters
# This script installs Gateway API controllers and sets up gateways

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
CLUSTER_NAME=""
NAMESPACE="default"
GATEWAY_CONTROLLER="nginx"
INSTALL_CRDS=true
CONFIGURE_METALLB=true

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

Install Gateway API and controllers on a CAPI-managed cluster.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster (required)
    -ns, --namespace NAMESPACE  Cluster namespace (default: default)
    -c, --controller CONTROLLER Gateway controller: nginx, istio, cilium (default: nginx)
    --no-crds                   Don't install Gateway API CRDs
    --no-metallb               Don't configure MetalLB for gateways
    -h, --help                  Show this help message

EXAMPLES:
    # Install NGINX Gateway on cluster
    $0 --name dev-cluster

    # Install Istio Gateway
    $0 --name prod-cluster --controller istio

    # Install without MetalLB configuration
    $0 --name test-cluster --no-metallb
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -ns|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -c|--controller)
                GATEWAY_CONTROLLER="$2"
                shift 2
                ;;
            --no-crds)
                INSTALL_CRDS=false
                shift
                ;;
            --no-metallb)
                CONFIGURE_METALLB=false
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

    if [[ -z "$CLUSTER_NAME" ]]; then
        log_error "Cluster name is required. Use --name to specify."
    fi

    if [[ "$GATEWAY_CONTROLLER" != "nginx" && "$GATEWAY_CONTROLLER" != "istio" && "$GATEWAY_CONTROLLER" != "cilium" ]]; then
        log_error "Unsupported gateway controller: $GATEWAY_CONTROLLER"
    fi
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if cluster exists
    if ! kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Cluster '$CLUSTER_NAME' not found in namespace '$NAMESPACE'"
    fi
    
    # Check if cluster is ready
    local cluster_phase
    cluster_phase=$(kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    
    if [[ "$cluster_phase" != "Provisioned" ]]; then
        log_error "Cluster is not ready. Current phase: $cluster_phase"
    fi
    
    # Check if kubeconfig exists
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    if [[ ! -f "$kubeconfig_file" ]]; then
        log_error "Kubeconfig not found at $kubeconfig_file"
    fi
    
    log_info "Prerequisites check completed."
}

install_gateway_api_crds() {
    if [[ "$INSTALL_CRDS" != "true" ]]; then
        log_info "Skipping Gateway API CRDs installation."
        return
    fi
    
    log_step "Installing Gateway API CRDs..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Install Gateway API CRDs
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
    
    # Install experimental features (for advanced routing)
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
    
    log_info "Gateway API CRDs installed successfully."
}

install_nginx_gateway() {
    log_step "Installing NGINX Gateway Fabric..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Create namespace
    kubectl --kubeconfig="$kubeconfig_file" create namespace nginx-gateway \
        --dry-run=client -o yaml | kubectl --kubeconfig="$kubeconfig_file" apply -f -
    
    # Install NGINX Gateway Fabric
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://github.com/nginxinc/nginx-gateway-fabric/releases/download/v1.1.0/nginx-gateway-fabric.yaml
    
    # Wait for deployment to be ready
    log_info "Waiting for NGINX Gateway to be ready..."
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=available \
        --timeout=300s deployment/nginx-gateway -n nginx-gateway
    
    log_info "NGINX Gateway Fabric installed successfully."
}

install_istio_gateway() {
    log_step "Installing Istio Gateway..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Install Istio
    log_info "Installing Istio..."
    curl -L https://istio.io/downloadIstio | sh -
    export PATH="$PWD/istio-*/bin:$PATH"
    
    istioctl --kubeconfig="$kubeconfig_file" install --set values.defaultRevision=default -y
    
    # Enable Istio injection for default namespace
    kubectl --kubeconfig="$kubeconfig_file" label namespace default istio-injection=enabled --overwrite
    
    log_info "Istio Gateway installed successfully."
}

install_cilium_gateway() {
    log_step "Installing Cilium Gateway..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Install Cilium CLI
    if ! command -v cilium &> /dev/null; then
        log_info "Installing Cilium CLI..."
        curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
        sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
        sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
        rm cilium-linux-amd64.tar.gz{,.sha256sum}
    fi
    
    # Install Cilium with Gateway API support
    cilium --kubeconfig="$kubeconfig_file" install \
        --set kubeProxyReplacement=strict \
        --set gatewayAPI.enabled=true
    
    # Wait for Cilium to be ready
    cilium --kubeconfig="$kubeconfig_file" status --wait
    
    log_info "Cilium Gateway installed successfully."
}

configure_metallb_pools() {
    if [[ "$CONFIGURE_METALLB" != "true" ]]; then
        log_info "Skipping MetalLB configuration."
        return
    fi
    
    log_step "Configuring MetalLB IP pools for gateways..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Create separate IP pools for internal and external gateways
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: internal-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.20.200-10.0.20.209  # Internal gateway IPs
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: external-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.20.210-10.0.20.219  # External gateway IPs
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: internal-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - internal-pool
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: external-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - external-pool
EOF
    
    log_info "MetalLB pools configured for gateways."
}

deploy_gateway_resources() {
    log_step "Deploying Gateway API resources..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    local temp_dir="/tmp/gateway-${CLUSTER_NAME}"
    
    mkdir -p "$temp_dir"
    
    # Process templates and substitute cluster name
    for file in "$PROJECT_ROOT/kubernetes/capi/addons/gateway-api"/*.yaml; do
        if [[ -f "$file" ]]; then
            local temp_file="$temp_dir/$(basename "$file")"
            sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" "$file" > "$temp_file"
            kubectl --kubeconfig="$kubeconfig_file" apply -f "$temp_file"
        fi
    done
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    # Wait for gateways to be ready
    log_info "Waiting for gateways to be ready..."
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Programmed \
        --timeout=300s gateway/internal-gateway -n nginx-gateway || log_warn "Internal gateway not ready"
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Programmed \
        --timeout=300s gateway/external-gateway -n nginx-gateway || log_warn "External gateway not ready"
    
    log_info "Gateway API resources deployed."
}

install_controller() {
    case $GATEWAY_CONTROLLER in
        "nginx")
            install_nginx_gateway
            ;;
        "istio")
            install_istio_gateway
            ;;
        "cilium")
            install_cilium_gateway
            ;;
        *)
            log_error "Unsupported gateway controller: $GATEWAY_CONTROLLER"
            ;;
    esac
}

display_gateway_info() {
    log_step "Gateway Information"
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    echo ""
    echo "🎉 Gateway API installation completed!"
    echo ""
    echo "Gateway Controller: $GATEWAY_CONTROLLER"
    echo "Cluster: $CLUSTER_NAME"
    echo ""
    
    # Show gateway status
    echo "Gateway Status:"
    kubectl --kubeconfig="$kubeconfig_file" get gateways -A -o wide 2>/dev/null || echo "No gateways found"
    echo ""
    
    # Show gateway services
    echo "Gateway Services:"
    kubectl --kubeconfig="$kubeconfig_file" get services -n nginx-gateway 2>/dev/null || echo "No gateway services found"
    echo ""
    
    # Show IP addresses
    echo "Gateway IP Addresses:"
    local internal_ip external_ip
    internal_ip=$(kubectl --kubeconfig="$kubeconfig_file" get service internal-gateway-service -n nginx-gateway \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    external_ip=$(kubectl --kubeconfig="$kubeconfig_file" get service external-gateway-service -n nginx-gateway \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending")
    
    echo "  Internal Gateway: $internal_ip"
    echo "  External Gateway: $external_ip"
    echo ""
    
    echo "Next Steps:"
    echo "1. Create HTTPRoute resources for your applications"
    echo "2. Configure Cloudflare Tunnel to point to external gateway"
    echo "3. Test routing with: kubectl get httproutes -A"
    echo ""
    echo "Example HTTPRoute creation:"
    echo "  kubectl apply -f kubernetes/capi/addons/gateway-api/httproutes/"
}

main() {
    echo "=========================================="
    echo "Gateway API Installation for CAPI"
    echo "=========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    install_gateway_api_crds
    install_controller
    configure_metallb_pools
    deploy_gateway_resources
    display_gateway_info
    
    log_info "Gateway API installation completed successfully!"
}

# Run main function
main "$@"