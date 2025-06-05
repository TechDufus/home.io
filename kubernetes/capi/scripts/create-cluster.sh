#!/bin/bash
set -euo pipefail

# CAPI Cluster Creation Script
# This script creates a new Kubernetes cluster using Cluster API

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
ENVIRONMENT="dev"
NAMESPACE="default"
WAIT_FOR_READY=true
INSTALL_CNI=true
INSTALL_ADDONS=false
USE_1PASSWORD=false

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

Create a new Kubernetes cluster using Cluster API.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster to create (required)
    -e, --env ENVIRONMENT       Environment: dev, prod (default: dev)
    -ns, --namespace NAMESPACE  Kubernetes namespace (default: default)
    --no-wait                   Don't wait for cluster to be ready
    --no-cni                    Don't install CNI automatically
    --install-addons           Install additional addons (MetalLB, Gateway API, Ingress)
    --use-1password            Enable 1Password secret management integration
    -h, --help                  Show this help message

EXAMPLES:
    # Create a dev cluster
    $0 --name my-dev-cluster --env dev

    # Create a production cluster with addons
    $0 --name my-prod-cluster --env prod --install-addons

    # Create cluster without waiting
    $0 --name test-cluster --no-wait
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
            -ns|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --no-wait)
                WAIT_FOR_READY=false
                shift
                ;;
            --no-cni)
                INSTALL_CNI=false
                shift
                ;;
            --install-addons)
                INSTALL_ADDONS=true
                shift
                ;;
            --use-1password)
                USE_1PASSWORD=true
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

    if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
        log_error "Environment must be 'dev' or 'prod'"
    fi
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if management cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster. Make sure management cluster is running."
    fi
    
    # Check if CAPI is installed
    if ! kubectl get crd clusters.cluster.x-k8s.io &> /dev/null; then
        log_error "Cluster API not found. Run bootstrap/install-capi.sh first."
    fi
    
    # Check if clusterctl is available
    if ! command -v clusterctl &> /dev/null; then
        log_error "clusterctl not found. Please install clusterctl."
    fi
    
    # Check if cluster already exists
    if kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Cluster '$CLUSTER_NAME' already exists in namespace '$NAMESPACE'"
    fi
    
    log_info "Prerequisites check completed."
}

create_cluster_from_template() {
    log_step "Creating cluster from template..."
    
    local template_file="$PROJECT_ROOT/kubernetes/capi/clusters/environments/$ENVIRONMENT/cluster.yaml"
    local temp_file="/tmp/cluster-${CLUSTER_NAME}.yaml"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
    fi
    
    # Copy template and substitute cluster name
    sed "s/\(name: \)\(.*-cluster\)/\1$CLUSTER_NAME/g" "$template_file" > "$temp_file"
    sed -i "s/\(cluster.x-k8s.io\/cluster-name: \)\(.*-cluster\)/\1$CLUSTER_NAME/g" "$temp_file"
    sed -i "s/\(clusterName: \)\(.*-cluster\)/\1$CLUSTER_NAME/g" "$temp_file"
    
    # Update control plane endpoint
    local control_plane_host="${CLUSTER_NAME}-api.home.io"
    sed -i "s/\(host: \)\(.*-api\.home\.io\)/\1$control_plane_host/g" "$temp_file"
    
    # Apply the cluster configuration
    kubectl apply -f "$temp_file" -n "$NAMESPACE"
    
    # Clean up temp file
    rm "$temp_file"
    
    log_info "Cluster manifests applied successfully."
}

wait_for_cluster_ready() {
    if [[ "$WAIT_FOR_READY" != "true" ]]; then
        log_info "Skipping wait for cluster ready."
        return
    fi
    
    log_step "Waiting for cluster to be ready..."
    
    log_info "Waiting for control plane to be ready..."
    kubectl wait --for=condition=Ready \
        --timeout=1200s \
        cluster "$CLUSTER_NAME" \
        -n "$NAMESPACE"
    
    log_info "Waiting for control plane machines to be ready..."
    kubectl wait --for=condition=Ready \
        --timeout=900s \
        kubeadmcontrolplane "${CLUSTER_NAME}-control-plane" \
        -n "$NAMESPACE"
    
    log_info "Waiting for worker machines to be ready..."
    kubectl wait --for=condition=Ready \
        --timeout=900s \
        machinedeployment "${CLUSTER_NAME}-workers" \
        -n "$NAMESPACE"
    
    log_info "Cluster is ready!"
}

get_cluster_kubeconfig() {
    log_step "Retrieving cluster kubeconfig..."
    
    local kubeconfig_dir="$HOME/.kube"
    local kubeconfig_file="$kubeconfig_dir/config-${CLUSTER_NAME}"
    
    mkdir -p "$kubeconfig_dir"
    
    # Get kubeconfig from the workload cluster
    clusterctl get kubeconfig "$CLUSTER_NAME" -n "$NAMESPACE" > "$kubeconfig_file"
    
    log_info "Kubeconfig saved to: $kubeconfig_file"
    echo "To use this cluster, run:"
    echo "  export KUBECONFIG=$kubeconfig_file"
    echo "  kubectl get nodes"
}

install_cni() {
    if [[ "$INSTALL_CNI" != "true" ]]; then
        log_info "Skipping CNI installation."
        return
    fi
    
    log_step "Installing CNI (Calico)..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Install Tigera operator
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
    
    # Apply Calico configuration
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
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
    log_info "Waiting for Calico to be ready..."
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Ready \
        pods -l k8s-app=calico-node -n calico-system --timeout=300s
    
    log_info "CNI installed successfully."
}

install_addons() {
    if [[ "$INSTALL_ADDONS" != "true" ]]; then
        log_info "Skipping addon installation."
        return
    fi
    
    log_step "Installing cluster addons..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Install MetalLB
    log_info "Installing MetalLB..."
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
    
    # Wait for MetalLB to be ready
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=ready \
        pods -l component=controller -n metallb-system --timeout=120s
    
    # Configure MetalLB IP pools for Gateway API
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
kind: IPAddressPool
metadata:
  name: ingress-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.20.220-10.0.20.230  # Legacy ingress IPs
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
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ingress-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - ingress-pool
EOF
    
    # Install Gateway API using dedicated script
    log_info "Installing Gateway API..."
    if [[ -f "$SCRIPT_DIR/install-gateway-api.sh" ]]; then
        "$SCRIPT_DIR/install-gateway-api.sh" --name "$CLUSTER_NAME" --namespace "$NAMESPACE"
    else
        log_warn "Gateway API installation script not found, installing manually..."
        
        # Install Gateway API CRDs
        kubectl --kubeconfig="$kubeconfig_file" apply -f \
            https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
        kubectl --kubeconfig="$kubeconfig_file" apply -f \
            https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
        
        # Install NGINX Gateway Fabric
        kubectl --kubeconfig="$kubeconfig_file" create namespace nginx-gateway \
            --dry-run=client -o yaml | kubectl --kubeconfig="$kubeconfig_file" apply -f -
        kubectl --kubeconfig="$kubeconfig_file" apply -f \
            https://github.com/nginxinc/nginx-gateway-fabric/releases/download/v1.1.0/nginx-gateway-fabric.yaml
    fi
    
    # Install legacy Ingress-NGINX for backward compatibility (optional)
    log_info "Installing Ingress-NGINX for backward compatibility..."
    kubectl --kubeconfig="$kubeconfig_file" apply -f \
        https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml
    
    # Patch ingress controller to use LoadBalancer from ingress pool
    kubectl --kubeconfig="$kubeconfig_file" patch service ingress-nginx-controller \
        -n ingress-nginx -p '{"spec":{"type":"LoadBalancer"}}'
    kubectl --kubeconfig="$kubeconfig_file" annotate service ingress-nginx-controller \
        -n ingress-nginx metallb.universe.tf/address-pool=ingress-pool
    
    log_info "Addons installed successfully (Gateway API + legacy Ingress)."
}

install_1password_operator() {
    if [[ "$USE_1PASSWORD" != "true" ]]; then
        log_info "Skipping 1Password operator installation."
        return
    fi
    
    log_step "Installing 1Password Secret Operator..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Check if 1Password operator token is available
    if [[ -z "${ONEPASSWORD_OPERATOR_TOKEN:-}" ]]; then
        log_error "1Password operator token not found. Run 1password-bootstrap.sh first or set ONEPASSWORD_OPERATOR_TOKEN."
    fi
    
    # Deploy 1Password operator
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
    
    # Deploy environment-specific secret references
    local secrets_file="$PROJECT_ROOT/kubernetes/secrets/secret-references/${ENVIRONMENT}-secrets.yaml"
    if [[ -f "$secrets_file" ]]; then
        log_info "Deploying $ENVIRONMENT environment secret references..."
        sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" "$secrets_file" | \
            kubectl --kubeconfig="$kubeconfig_file" apply -f -
    fi
    
    log_info "1Password Secret Operator installed successfully."
}

display_cluster_info() {
    log_step "Cluster Information"
    
    echo ""
    echo "🎉 Cluster '$CLUSTER_NAME' created successfully!"
    echo ""
    echo "Cluster Details:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace: $NAMESPACE"
    echo ""
    echo "Kubeconfig: $HOME/.kube/config-${CLUSTER_NAME}"
    echo ""
    echo "To access your cluster:"
    echo "  export KUBECONFIG=$HOME/.kube/config-${CLUSTER_NAME}"
    echo "  kubectl get nodes"
    echo ""
    echo "To delete this cluster:"
    echo "  $SCRIPT_DIR/delete-cluster.sh --name $CLUSTER_NAME"
    echo ""
    
    if [[ "$INSTALL_ADDONS" == "true" ]]; then
        echo "Installed addons:"
        echo "  - Calico CNI"
        echo "  - MetalLB LoadBalancer (with Gateway API pools)"
        echo "  - Gateway API (NGINX Gateway Fabric)"
        echo "  - Ingress-NGINX (legacy compatibility)"
        if [[ "$USE_1PASSWORD" == "true" ]]; then
            echo "  - 1Password Secret Operator"
        fi
        echo ""
        echo "Gateway API Resources:"
        echo "  - Internal Gateway: *.${CLUSTER_NAME}.home.io"
        echo "  - External Gateway: *.${CLUSTER_NAME}.lab.techdufus.com"
        echo ""
        echo "Next steps:"
        echo "  - Install ArgoCD: $SCRIPT_DIR/install-argocd.sh --name $CLUSTER_NAME"
        echo "  - Setup external access: $SCRIPT_DIR/setup-external-access.sh --name $CLUSTER_NAME"
        echo "  - Check Gateway status: kubectl get gateways -A --kubeconfig=$HOME/.kube/config-${CLUSTER_NAME}"
        echo ""
    fi
}

cleanup_on_error() {
    if [[ $? -ne 0 ]]; then
        log_error "Cluster creation failed. You may need to clean up manually:"
        echo "  kubectl delete cluster $CLUSTER_NAME -n $NAMESPACE"
    fi
}

main() {
    trap cleanup_on_error ERR
    
    echo "=========================================="
    echo "CAPI Cluster Creation"
    echo "=========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    create_cluster_from_template
    wait_for_cluster_ready
    get_cluster_kubeconfig
    install_cni
    install_addons
    install_1password_operator
    display_cluster_info
    
    log_info "Cluster creation completed successfully!"
}

# Run main function
main "$@"