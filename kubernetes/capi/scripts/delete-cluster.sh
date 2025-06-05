#!/bin/bash
set -euo pipefail

# CAPI Cluster Deletion Script
# This script safely deletes a Kubernetes cluster managed by Cluster API

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
FORCE_DELETE=false
SKIP_CONFIRMATION=false

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

Delete a Kubernetes cluster managed by Cluster API.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster to delete (required)
    -ns, --namespace NAMESPACE  Kubernetes namespace (default: default)
    -f, --force                 Force deletion even if cluster has workloads
    -y, --yes                   Skip confirmation prompts
    -h, --help                  Show this help message

EXAMPLES:
    # Delete a cluster with confirmation
    $0 --name my-cluster

    # Force delete without confirmation
    $0 --name my-cluster --force --yes

    # Delete cluster in specific namespace
    $0 --name my-cluster --namespace production
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
            -f|--force)
                FORCE_DELETE=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
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
    
    # Check if management cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot access Kubernetes cluster. Make sure management cluster is running."
    fi
    
    # Check if cluster exists
    if ! kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" &> /dev/null; then
        log_error "Cluster '$CLUSTER_NAME' not found in namespace '$NAMESPACE'"
    fi
    
    # Check if clusterctl is available
    if ! command -v clusterctl &> /dev/null; then
        log_error "clusterctl not found. Please install clusterctl."
    fi
    
    log_info "Prerequisites check completed."
}

display_cluster_info() {
    log_step "Cluster Information"
    
    echo ""
    echo "Cluster to be deleted:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Namespace: $NAMESPACE"
    echo ""
    
    # Show cluster status
    echo "Current status:"
    kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" -o wide
    echo ""
    
    # Show machines
    echo "Machines:"
    kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" -o wide 2>/dev/null || true
    echo ""
}

check_cluster_workloads() {
    if [[ "$FORCE_DELETE" == "true" ]]; then
        log_warn "Force delete enabled, skipping workload check."
        return
    fi
    
    log_step "Checking for workloads in cluster..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    if [[ ! -f "$kubeconfig_file" ]]; then
        log_warn "Kubeconfig not found at $kubeconfig_file. Cannot check workloads."
        return
    fi
    
    # Check for running pods (excluding system namespaces)
    local workload_pods
    workload_pods=$(kubectl --kubeconfig="$kubeconfig_file" get pods \
        --all-namespaces \
        --field-selector=status.phase=Running \
        --output=jsonpath='{.items[?(@.metadata.namespace!="kube-system")][?(@.metadata.namespace!="kube-public")][?(@.metadata.namespace!="kube-node-lease")][?(@.metadata.namespace!="calico-system")][?(@.metadata.namespace!="tigera-operator")][?(@.metadata.namespace!="metallb-system")][?(@.metadata.namespace!="ingress-nginx")].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$workload_pods" ]]; then
        log_warn "Found running workloads in the cluster:"
        kubectl --kubeconfig="$kubeconfig_file" get pods \
            --all-namespaces \
            --field-selector=status.phase=Running \
            | grep -v "kube-system\|kube-public\|kube-node-lease\|calico-system\|tigera-operator\|metallb-system\|ingress-nginx" || true
        echo ""
        
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            read -p "Workloads found. Continue with deletion? (yes/no): " -r
            if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
                log_info "Deletion cancelled."
                exit 0
            fi
        fi
    fi
}

confirm_deletion() {
    if [[ "$SKIP_CONFIRMATION" == "true" ]]; then
        return
    fi
    
    echo ""
    log_warn "This will permanently delete the cluster and all associated resources."
    log_warn "This action cannot be undone."
    echo ""
    
    read -p "Are you sure you want to delete cluster '$CLUSTER_NAME'? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_info "Deletion cancelled."
        exit 0
    fi
    
    echo ""
    read -p "Type the cluster name '$CLUSTER_NAME' to confirm: " -r
    if [[ "$REPLY" != "$CLUSTER_NAME" ]]; then
        log_error "Cluster name does not match. Deletion cancelled."
    fi
}

drain_cluster_workloads() {
    log_step "Draining cluster workloads..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    if [[ ! -f "$kubeconfig_file" ]]; then
        log_warn "Kubeconfig not found. Skipping workload drainage."
        return
    fi
    
    # Get all nodes
    local nodes
    nodes=$(kubectl --kubeconfig="$kubeconfig_file" get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$nodes" ]]; then
        log_info "Draining nodes..."
        for node in $nodes; do
            log_info "Draining node: $node"
            kubectl --kubeconfig="$kubeconfig_file" drain "$node" \
                --ignore-daemonsets \
                --delete-emptydir-data \
                --force \
                --timeout=300s || log_warn "Failed to drain node $node"
        done
    fi
}

delete_cluster() {
    log_step "Deleting cluster..."
    
    # Delete the cluster resource (this will trigger deletion of all associated resources)
    kubectl delete cluster "$CLUSTER_NAME" -n "$NAMESPACE" --timeout=300s
    
    log_info "Cluster deletion initiated."
}

wait_for_deletion() {
    log_step "Waiting for cluster deletion to complete..."
    
    # Wait for cluster to be fully deleted
    local timeout=1200  # 20 minutes
    local elapsed=0
    local interval=10
    
    while kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" &> /dev/null; do
        if [[ $elapsed -ge $timeout ]]; then
            log_warn "Timeout waiting for cluster deletion. Some resources may still exist."
            break
        fi
        
        echo -n "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    echo ""
    
    # Check for any remaining machines
    local remaining_machines
    remaining_machines=$(kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ "$remaining_machines" -gt 0 ]]; then
        log_warn "Some machines may still be terminating:"
        kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" || true
    fi
    
    log_info "Cluster deletion completed."
}

cleanup_kubeconfig() {
    log_step "Cleaning up kubeconfig..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    if [[ -f "$kubeconfig_file" ]]; then
        rm "$kubeconfig_file"
        log_info "Removed kubeconfig: $kubeconfig_file"
    fi
}

force_cleanup() {
    if [[ "$FORCE_DELETE" != "true" ]]; then
        return
    fi
    
    log_step "Performing force cleanup..."
    
    # Force delete any stuck machines
    local stuck_machines
    stuck_machines=$(kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    
    if [[ -n "$stuck_machines" ]]; then
        log_info "Force deleting stuck machines..."
        for machine in $stuck_machines; do
            kubectl patch machine "$machine" -n "$NAMESPACE" --type='merge' -p='{"metadata":{"finalizers":null}}' || true
            kubectl delete machine "$machine" -n "$NAMESPACE" --force --grace-period=0 || true
        done
    fi
    
    # Force delete any stuck infrastructure resources
    local proxmox_machines
    proxmox_machines=$(kubectl get proxmoxmachines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || echo "")
    
    if [[ -n "$proxmox_machines" ]]; then
        log_info "Force deleting stuck Proxmox machines..."
        for machine in $proxmox_machines; do
            kubectl patch proxmoxmachine "$machine" -n "$NAMESPACE" --type='merge' -p='{"metadata":{"finalizers":null}}' || true
            kubectl delete proxmoxmachine "$machine" -n "$NAMESPACE" --force --grace-period=0 || true
        done
    fi
}

display_summary() {
    echo ""
    echo "=========================================="
    echo "Cluster Deletion Summary"
    echo "=========================================="
    echo ""
    echo "✅ Cluster '$CLUSTER_NAME' has been deleted"
    echo ""
    echo "Cleaned up:"
    echo "  - Cluster resource"
    echo "  - Control plane machines"
    echo "  - Worker machines"
    echo "  - Proxmox VMs"
    echo "  - Kubeconfig file"
    echo ""
    
    if [[ "$FORCE_DELETE" == "true" ]]; then
        log_warn "Force delete was used. Some resources may require manual cleanup."
    fi
}

main() {
    echo "=========================================="
    echo "CAPI Cluster Deletion"
    echo "=========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    display_cluster_info
    check_cluster_workloads
    confirm_deletion
    drain_cluster_workloads
    delete_cluster
    wait_for_deletion
    force_cleanup
    cleanup_kubeconfig
    display_summary
    
    log_info "Cluster deletion completed successfully!"
}

# Run main function
main "$@"