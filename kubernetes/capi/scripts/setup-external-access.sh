#!/bin/bash
set -euo pipefail

# Setup External Access for CAPI Clusters with Gateway API
# This script configures Cloudflare Tunnel and HTTPRoutes for external access to cluster services

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
TUNNEL_TOKEN=""
SERVICES=("argocd")

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

Setup external access via Cloudflare Tunnel and Gateway API HTTPRoutes for a CAPI-managed cluster.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster (required)
    -ns, --namespace NAMESPACE  Cluster namespace (default: default)
    -t, --token TOKEN          Cloudflare tunnel token (will prompt if not provided)
    -s, --services SERVICES    Comma-separated list of services (default: argocd)
    -h, --help                  Show this help message

EXAMPLES:
    # Setup external access for ArgoCD
    $0 --name dev-cluster

    # Setup multiple services
    $0 --name prod-cluster --services "argocd,grafana,app"

    # Provide tunnel token directly
    $0 --name dev-cluster --token "your-tunnel-token"
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
            -t|--token)
                TUNNEL_TOKEN="$2"
                shift 2
                ;;
            -s|--services)
                IFS=',' read -ra SERVICES <<< "$2"
                shift 2
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

get_tunnel_token() {
    if [[ -n "$TUNNEL_TOKEN" ]]; then
        return
    fi
    
    log_step "Cloudflare Tunnel Configuration"
    
    echo ""
    echo "To set up external access, you need to create a Cloudflare Tunnel:"
    echo ""
    echo "1. Go to https://one.dash.cloudflare.com/"
    echo "2. Navigate to Access → Tunnels"
    echo "3. Create a tunnel named '${CLUSTER_NAME}-tunnel'"
    echo "4. Copy the tunnel token"
    echo ""
    
    read -p "Enter your tunnel token: " -r TUNNEL_TOKEN
    
    if [[ -z "$TUNNEL_TOKEN" ]]; then
        log_error "Tunnel token is required."
    fi
}

create_tunnel_secret() {
    log_step "Creating tunnel secret..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Base64 encode the token
    local encoded_token
    encoded_token=$(echo -n "$TUNNEL_TOKEN" | base64)
    
    # Create namespace
    kubectl --kubeconfig="$kubeconfig_file" create namespace cloudflare-tunnel \
        --dry-run=client -o yaml | kubectl --kubeconfig="$kubeconfig_file" apply -f -
    
    # Create secret
    cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-tunnel-token
  namespace: cloudflare-tunnel
type: Opaque
data:
  token: "$encoded_token"
EOF
    
    log_info "Tunnel secret created."
}

deploy_tunnel_config() {
    log_step "Deploying Gateway API tunnel configuration..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    local temp_dir="/tmp/tunnel-gateway-${CLUSTER_NAME}"
    
    mkdir -p "$temp_dir"
    
    # Use the existing Gateway API tunnel configuration
    if [[ -d "$PROJECT_ROOT/kubernetes/capi/addons/cloudflare-tunnel-gateway" ]]; then
        log_info "Deploying Gateway API tunnel configuration..."
        
        # Process templates with cluster name substitution
        for file in "$PROJECT_ROOT/kubernetes/capi/addons/cloudflare-tunnel-gateway"/*.yaml; do
            if [[ -f "$file" ]]; then
                local temp_file="$temp_dir/$(basename "$file")"
                sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" "$file" > "$temp_file"
                kubectl --kubeconfig="$kubeconfig_file" apply -f "$temp_file"
            fi
        done
    else
        log_warn "Gateway API tunnel configuration not found, creating basic config..."
        
        # Create basic Gateway API tunnel configuration
        cat <<EOF | kubectl --kubeconfig="$kubeconfig_file" apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloudflare-tunnel-config
  namespace: cloudflare-tunnel
data:
  config.yaml: |
    tunnel: ${CLUSTER_NAME}-tunnel
    credentials-file: /etc/cloudflared/creds/credentials.json
    
    # With Gateway API, tunnel points to the external gateway service
    # The gateway handles routing based on hostname headers
    ingress:
      # All external traffic goes through the external gateway
      - hostname: "*.${CLUSTER_NAME}.lab.techdufus.com"
        service: http://external-gateway-service.nginx-gateway.svc.cluster.local:80
        originRequest:
          httpHostHeader: "*.${CLUSTER_NAME}.lab.techdufus.com"
          http2Origin: true
          connectTimeout: 10s
          tlsTimeout: 10s
          tcpKeepAlive: 30s
          keepAliveConnections: 100
          keepAliveTimeout: 90s
      
      # Catch-all rule (required)
      - service: http_status:404
    
    # Logging configuration
    log:
      level: info
      format: json
    
    # Metrics for monitoring tunnel performance  
    metrics: 0.0.0.0:9090
    
    # Tunnel features
    features:
      - http2
      - connection-pool
    
    # Retry configuration for reliability
    retries: 3
    retry-timeout: 30s
    
    # Grace period for graceful shutdown
    grace-period: 30s
EOF
    fi
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    log_info "Gateway API tunnel configuration deployed."
}

deploy_httproutes() {
    log_step "Deploying HTTPRoutes for requested services..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    local temp_dir="/tmp/httproutes-${CLUSTER_NAME}"
    
    mkdir -p "$temp_dir"
    
    # Deploy HTTPRoutes for each requested service
    for service in "${SERVICES[@]}"; do
        local template_file="$PROJECT_ROOT/kubernetes/capi/addons/gateway-api/httproutes/${service}.yaml"
        
        if [[ -f "$template_file" ]]; then
            log_info "Deploying HTTPRoutes for $service..."
            local temp_file="$temp_dir/${service}-httproutes.yaml"
            sed "s/\${CLUSTER_NAME}/$CLUSTER_NAME/g" "$template_file" > "$temp_file"
            kubectl --kubeconfig="$kubeconfig_file" apply -f "$temp_file"
        else
            log_warn "HTTPRoute template not found for service: $service. Skipping."
            log_info "Available templates: argocd, grafana"
            log_info "Create custom HTTPRoute using template: $PROJECT_ROOT/kubernetes/capi/addons/gateway-api/httproutes/app-template.yaml"
        fi
    done
    
    # Clean up temp files
    rm -rf "$temp_dir"
    
    # Wait for HTTPRoutes to be accepted
    log_info "Waiting for HTTPRoutes to be accepted..."
    for service in "${SERVICES[@]}"; do
        if kubectl --kubeconfig="$kubeconfig_file" get httproute "${service}-internal" -n "$(get_service_namespace "$service")" &>/dev/null; then
            kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Accepted \
                --timeout=60s httproute "${service}-internal" -n "$(get_service_namespace "$service")" || log_warn "HTTPRoute ${service}-internal not accepted"
        fi
        if kubectl --kubeconfig="$kubeconfig_file" get httproute "${service}-external" -n "$(get_service_namespace "$service")" &>/dev/null; then
            kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=Accepted \
                --timeout=60s httproute "${service}-external" -n "$(get_service_namespace "$service")" || log_warn "HTTPRoute ${service}-external not accepted"
        fi
    done
    
    log_info "HTTPRoutes deployed successfully."
}

get_service_namespace() {
    local service="$1"
    case $service in
        "argocd") echo "argocd" ;;
        "grafana") echo "monitoring" ;;
        *) echo "default" ;;
    esac
}

wait_for_tunnel_ready() {
    log_step "Waiting for Cloudflare Tunnel to be ready..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    # Wait for tunnel deployment to be ready
    kubectl --kubeconfig="$kubeconfig_file" wait --for=condition=available \
        --timeout=300s deployment/cloudflare-tunnel -n cloudflare-tunnel || log_warn "Tunnel deployment not ready"
    
    log_info "Cloudflare Tunnel is ready."
}

display_access_info() {
    log_step "External Access Information"
    
    echo ""
    echo "🎉 External access configured successfully!"
    echo ""
    echo "Cluster: $CLUSTER_NAME"
    echo "Services exposed:"
    
    for service in "${SERVICES[@]}"; do
        case $service in
            "argocd")
                echo "  ArgoCD:"
                echo "    Internal: https://argocd.${CLUSTER_NAME}.home.io"
                echo "    External: https://argocd.${CLUSTER_NAME}.lab.techdufus.com"
                ;;
            "grafana")
                echo "  Grafana:"
                echo "    Internal: https://grafana.${CLUSTER_NAME}.home.io"
                echo "    External: https://grafana.${CLUSTER_NAME}.lab.techdufus.com"
                ;;
            "app")
                echo "  Custom App:"
                echo "    Internal: https://app.${CLUSTER_NAME}.home.io"
                echo "    External: https://app.${CLUSTER_NAME}.lab.techdufus.com"
                ;;
        esac
    done
    
    echo ""
    echo "Gateway API Configuration:"
    echo "  • Tunnel routes all *.${CLUSTER_NAME}.lab.techdufus.com to external-gateway"
    echo "  • HTTPRoutes handle service-specific routing"
    echo "  • Internal access via *.${CLUSTER_NAME}.home.io through internal-gateway"
    echo ""
    echo "Next Steps:"
    echo "1. Configure DNS records in Cloudflare dashboard"
    echo "2. Set SSL/TLS mode to 'Full (strict)'"
    echo "3. Test external access to your services"
    echo "4. Add more services by creating HTTPRoute resources"
    echo ""
    echo "DNS Records to add (wildcard covers all services):"
    echo "  *.${CLUSTER_NAME}.lab.techdufus.com → <tunnel-id>.cfargotunnel.com"
    echo ""
    echo "Gateway API Resources:"
    echo "  • Check gateways: kubectl get gateways -A"
    echo "  • Check routes: kubectl get httproutes -A"
    echo "  • Check gateway status: kubectl describe gateway external-gateway -n nginx-gateway"
    
    # Save access info
    local info_file="$HOME/external-access-${CLUSTER_NAME}-info.txt"
    cat > "$info_file" << EOF
External Access Information for $CLUSTER_NAME
=============================================

Tunnel Name: ${CLUSTER_NAME}-tunnel

Services:
$(for service in "${SERVICES[@]}"; do
    case $service in
        "argocd")
            echo "ArgoCD:"
            echo "  Internal: https://argocd.${CLUSTER_NAME}.home.io"
            echo "  External: https://argocd.${CLUSTER_NAME}.lab.techdufus.com"
            ;;
        "grafana")
            echo "Grafana:"
            echo "  Internal: https://grafana.${CLUSTER_NAME}.home.io"
            echo "  External: https://grafana.${CLUSTER_NAME}.lab.techdufus.com"
            ;;
    esac
done)

Setup Date: $(date)
EOF
    
    echo "Access information saved to: $info_file"
}

main() {
    echo "================================================="
    echo "CAPI Cluster External Access Setup (Gateway API)"
    echo "================================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    get_tunnel_token
    create_tunnel_secret
    deploy_tunnel_config
    deploy_httproutes
    wait_for_tunnel_ready
    display_access_info
    
    log_info "External access setup completed successfully!"
}

# Run main function
main "$@"