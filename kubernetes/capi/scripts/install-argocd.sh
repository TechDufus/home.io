#!/bin/bash
set -euo pipefail

# ArgoCD Installation Script for CAPI-managed clusters
# This script installs ArgoCD on a workload cluster and configures it for GitOps

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
ARGOCD_VERSION="v2.9.3"
REPO_URL="https://github.com/techdufus/home.io"
INSTALL_HTTPROUTES=true
CONFIGURE_APPS=true

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

Install and configure ArgoCD on a CAPI-managed Kubernetes cluster.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster (required)
    -ns, --namespace NAMESPACE  Cluster namespace (default: default)
    -v, --version VERSION       ArgoCD version (default: $ARGOCD_VERSION)
    -r, --repo REPO_URL         Git repository URL (default: $REPO_URL)
    --no-httproutes            Don't install HTTPRoute configuration
    --no-apps                  Don't configure ArgoCD applications
    -h, --help                  Show this help message

EXAMPLES:
    # Install ArgoCD on a cluster
    $0 --name my-cluster

    # Install specific version without apps
    $0 --name my-cluster --version v2.8.0 --no-apps

    # Install with custom repository
    $0 --name my-cluster --repo https://github.com/myuser/myrepo
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
            -v|--version)
                ARGOCD_VERSION="$2"
                shift 2
                ;;
            -r|--repo)
                REPO_URL="$2"
                shift 2
                ;;
            --no-httproutes)
                INSTALL_HTTPROUTES=false
                shift
                ;;
            --no-apps)
                CONFIGURE_APPS=false
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

install_argocd() {
    log_step "Installing ArgoCD..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Create ArgoCD namespace
    kubectl --kubeconfig="$kubeconfig_file" create namespace argocd --dry-run=client -o yaml | \
        kubectl --kubeconfig="$kubeconfig_file" apply -f -
    
    # Install ArgoCD
    kubectl --kubeconfig="$kubeconfig_file" apply -n argocd -f \
        "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
    
    # Wait for ArgoCD to be ready
    log_info "Waiting for ArgoCD pods to be ready..."
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Ready \
        pods -l app.kubernetes.io/part-of=argocd -n argocd --timeout=600s
    
    log_info "ArgoCD installed successfully."
}

configure_argocd_server() {
    log_step "Configuring ArgoCD server..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Configure ArgoCD server
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-server-config
  namespace: argocd
data:
  url: "https://argocd.${CLUSTER_NAME}.lab.techdufus.com"
  application.instanceLabelKey: argocd.argoproj.io/instance
  server.rbac.log.enforce.enable: "false"
  exec.enabled: "false"
  admin.enabled: "true"
  timeout.reconciliation: 180s
  timeout.hard.reconciliation: 0s
  resource.customizations: |
    admissionregistration.k8s.io/MutatingWebhookConfiguration:
      ignoreDifferences: |
        jsonPointers:
        - /webhooks/0/clientConfig/caBundle
    admissionregistration.k8s.io/ValidatingWebhookConfiguration:
      ignoreDifferences: |
        jsonPointers:
        - /webhooks/0/clientConfig/caBundle
EOF

    # Configure RBAC
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    p, role:readonly, applications, get, */*, allow
    p, role:readonly, certificates, get, *, allow
    p, role:readonly, clusters, get, *, allow
    p, role:readonly, repositories, get, *, allow
    g, argocd-readonly, role:readonly
  policy.default: role:readonly
EOF

    log_info "ArgoCD server configured."
}

install_httproutes() {
    if [[ "$INSTALL_HTTPROUTES" != "true" ]]; then
        log_info "Skipping HTTPRoute installation."
        return
    fi
    
    log_step "Installing ArgoCD HTTPRoutes..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    local temp_dir="/tmp/argocd-httproutes-${CLUSTER_NAME}"
    
    mkdir -p "$temp_dir"
    
    # Process ArgoCD HTTPRoute template with cluster name substitution
    if [[ -f "$PROJECT_ROOT/kubernetes/capi/addons/gateway-api/httproutes/argocd.yaml" ]]; then
        local temp_file="$temp_dir/argocd-httproutes.yaml"
        sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" \
            "$PROJECT_ROOT/kubernetes/capi/addons/gateway-api/httproutes/argocd.yaml" > "$temp_file"
        kubectl --kubeconfig="$kubeconfig_file" apply -f "$temp_file"
    else
        log_warn "ArgoCD HTTPRoute template not found, creating inline..."
        
        # Create HTTPRoutes inline if template is missing
        cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: argocd-internal
  namespace: argocd
  annotations:
    gateway.networking.k8s.io/description: "Internal access to ArgoCD"
spec:
  parentRefs:
  - name: internal-gateway
    namespace: nginx-gateway
    sectionName: http-internal
  hostnames:
  - "argocd.${CLUSTER_NAME}.home.io"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: argocd-server
      port: 80
      weight: 100
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        set:
        - name: X-Forwarded-Proto
          value: http
        - name: X-Forwarded-Host
          value: "argocd.${CLUSTER_NAME}.home.io"
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: argocd-external
  namespace: argocd
  annotations:
    gateway.networking.k8s.io/description: "External access to ArgoCD via Cloudflare Tunnel"
spec:
  parentRefs:
  - name: external-gateway
    namespace: nginx-gateway
    sectionName: http-external
  hostnames:
  - "argocd.${CLUSTER_NAME}.lab.techdufus.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: argocd-server
      port: 80
      weight: 100
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        set:
        - name: X-Forwarded-Proto
          value: https
        - name: X-Forwarded-Host
          value: "argocd.${CLUSTER_NAME}.lab.techdufus.com"
        - name: X-Real-IP
          value: "%{REMOTE_ADDR}"
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        set:
        - name: X-Frame-Options
          value: SAMEORIGIN
        - name: X-Content-Type-Options
          value: nosniff
EOF
    fi
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    # Ensure ArgoCD server is ClusterIP type for HTTPRoute compatibility
    kubectl --kubeconfig="$kubeconfig_file" patch service argocd-server -n argocd -p \
        '{"spec":{"type":"ClusterIP"}}'
    
    log_info "ArgoCD HTTPRoutes installed."
}

get_admin_password() {
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Get ArgoCD admin password
    local admin_password
    admin_password=$(kubectl --kubeconfig="$kubeconfig_file" get secret argocd-initial-admin-secret \
        -n argocd -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || echo "")
    
    if [[ -n "$admin_password" ]]; then
        echo "$admin_password"
    else
        echo "Unable to retrieve admin password"
    fi
}

configure_repository() {
    log_step "Configuring Git repository..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Add Git repository to ArgoCD
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: home-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: "$REPO_URL"
  type: git
EOF

    log_info "Git repository configured."
}

configure_applications() {
    if [[ "$CONFIGURE_APPS" != "true" ]]; then
        log_info "Skipping application configuration."
        return
    fi
    
    log_step "Configuring ArgoCD applications..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Create app project
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  sourceRepos:
  - '$REPO_URL'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
EOF

    # Create root application
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: '$REPO_URL'
    path: kubernetes/apps
    targetRevision: main
    directory:
      include: infrastructure.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

    log_info "ArgoCD applications configured."
}

install_argocd_cli() {
    log_step "Installing ArgoCD CLI..."
    
    # Check if argocd CLI is already installed
    if command -v argocd &> /dev/null; then
        log_info "ArgoCD CLI already installed: $(argocd version --client --short 2>/dev/null || echo 'argocd present')"
        return
    fi
    
    # Download and install ArgoCD CLI
    local os_name
    os_name=$(uname | tr '[:upper:]' '[:lower:]')
    
    curl -sSL -o /tmp/argocd-${os_name}-amd64 \
        "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-${os_name}-amd64"
    
    chmod +x /tmp/argocd-${os_name}-amd64
    sudo mv /tmp/argocd-${os_name}-amd64 /usr/local/bin/argocd
    
    log_info "ArgoCD CLI installed successfully."
}

display_access_info() {
    log_step "ArgoCD Access Information"
    
    local admin_password
    admin_password=$(get_admin_password)
    
    echo ""
    echo "🎉 ArgoCD installation completed!"
    echo ""
    echo "Access Information:"
    echo "  Internal URL: https://argocd.${CLUSTER_NAME}.home.io"
    echo "  External URL: https://argocd.${CLUSTER_NAME}.lab.techdufus.com"
    echo "  Username: admin"
    echo "  Password: $admin_password"
    echo ""
    echo "CLI Access:"
    echo "  argocd login argocd.${CLUSTER_NAME}.home.io"
    echo ""
    echo "Kubeconfig:"
    echo "  export KUBECONFIG=$HOME/.kube/config-${CLUSTER_NAME}"
    echo ""
    echo "Repository:"
    echo "  URL: $REPO_URL"
    echo "  Path: kubernetes/apps"
    echo ""
    
    # Save access info to file
    local info_file="$HOME/argocd-${CLUSTER_NAME}-info.txt"
    cat > "$info_file" << EOF
ArgoCD Access Information for $CLUSTER_NAME
==========================================

URL: https://argocd.${CLUSTER_NAME}.home.io
Username: admin
Password: $admin_password

CLI Login:
argocd login argocd.${CLUSTER_NAME}.home.io

Cluster Access:
export KUBECONFIG=$HOME/.kube/config-${CLUSTER_NAME}

Repository: $REPO_URL
Branch: main
Path: kubernetes/apps

Installation Date: $(date)
EOF
    
    echo "Access information saved to: $info_file"
}

main() {
    echo "=========================================="
    echo "ArgoCD Installation for CAPI Clusters"
    echo "=========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    install_argocd
    configure_argocd_server
    install_httproutes
    configure_repository
    configure_applications
    install_argocd_cli
    display_access_info
    
    log_info "ArgoCD installation completed successfully!"
}

# Run main function
main "$@"