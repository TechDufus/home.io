#!/bin/bash
# Install k3s on fresh Ubuntu VMs
# Installs server on control plane, then joins workers
# Usage: ./k3s-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Node configuration
CP_HOST="10.0.20.20"
WORKER_HOSTS=("10.0.20.21" "10.0.20.22")
SSH_USER="techdufus"

K3S_DISABLE="--disable traefik --disable servicelb --disable local-storage"
KUBECONFIG_LOCAL="${SCRIPT_DIR}/../../terraform/proxmox/environments/dev/kubeconfig"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${BLUE}k3s Cluster Install${NC}"
echo -e "${BLUE}===================${NC}"
echo ""

# Run command on remote host via SSH
remote_exec() {
    local host="$1"
    shift
    ssh -o StrictHostKeyChecking=accept-new "${SSH_USER}@${host}" "$@"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v ssh &> /dev/null; then
        log_error "ssh not found."
        exit 1
    fi

    # Verify SSH connectivity to all nodes
    for host in "$CP_HOST" "${WORKER_HOSTS[@]}"; do
        if ! ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "${SSH_USER}@${host}" true 2>/dev/null; then
            log_error "Cannot SSH to ${host} as ${SSH_USER}"
            exit 1
        fi
        log_info "  SSH to ${host} OK"
    done

    log_info "Prerequisites satisfied"
}

# Install k3s server on control plane
install_server() {
    log_info "Installing k3s server on ${CP_HOST}..."
    remote_exec "$CP_HOST" "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='${K3S_DISABLE}' sh -"
    log_info "k3s server installed on ${CP_HOST}"
}

# Get the join token from control plane
get_join_token() {
    remote_exec "$CP_HOST" "sudo cat /var/lib/rancher/k3s/server/node-token"
}

# Install k3s agent on a worker
install_worker() {
    local host="$1"
    local token="$2"

    log_info "Installing k3s agent on ${host}..."
    remote_exec "$host" "curl -sfL https://get.k3s.io | K3S_URL=https://${CP_HOST}:6443 K3S_TOKEN=${token} sh -"
    log_info "k3s agent installed on ${host}"
}

# Fetch kubeconfig and save locally
fetch_kubeconfig() {
    log_info "Fetching kubeconfig from control plane..."

    remote_exec "$CP_HOST" "sudo cat /etc/rancher/k3s/k3s.yaml" \
        | sed "s/127.0.0.1/${CP_HOST}/" \
        > "$KUBECONFIG_LOCAL"

    chmod 600 "$KUBECONFIG_LOCAL"
    log_info "Kubeconfig saved to ${KUBECONFIG_LOCAL}"
}

# Wait for all nodes to be Ready
wait_for_nodes() {
    local expected_count=$(( 1 + ${#WORKER_HOSTS[@]} ))

    log_info "Waiting for ${expected_count} nodes to be Ready..."
    export KUBECONFIG="$KUBECONFIG_LOCAL"

    local attempts=0
    local max_attempts=30
    while [ $attempts -lt $max_attempts ]; do
        local ready_count=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
        if [ "$ready_count" -ge "$expected_count" ]; then
            log_info "All ${expected_count} nodes are Ready"
            echo ""
            kubectl get nodes
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempts++))
    done

    echo ""
    log_warn "Timed out waiting for all nodes. Current status:"
    kubectl get nodes
    return 1
}

# Main execution
main() {
    check_prerequisites

    install_server

    log_info "Retrieving join token..."
    local token
    token=$(get_join_token)

    for host in "${WORKER_HOSTS[@]}"; do
        install_worker "$host" "$token"
    done

    fetch_kubeconfig
    wait_for_nodes

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}k3s cluster is ready!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  export KUBECONFIG=${KUBECONFIG_LOCAL}"
    echo "  ./setup-secrets.sh"
    echo "  ./argocd.sh"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0"
        echo ""
        echo "Install k3s on the homelab cluster VMs."
        echo ""
        echo "Nodes:"
        echo "  Control plane: ${SSH_USER}@${CP_HOST}"
        for host in "${WORKER_HOSTS[@]}"; do
            echo "  Worker:        ${SSH_USER}@${host}"
        done
        echo ""
        echo "k3s is installed with: ${K3S_DISABLE}"
        echo ""
        echo "Kubeconfig is saved to:"
        echo "  ${KUBECONFIG_LOCAL}"
        exit 0
        ;;
    *)
        main
        ;;
esac
