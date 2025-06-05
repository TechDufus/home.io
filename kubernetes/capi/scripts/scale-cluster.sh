#!/bin/bash
set -euo pipefail

# CAPI Cluster Scaling Script
# This script scales worker nodes in a Kubernetes cluster managed by Cluster API

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
WORKER_COUNT=""
WAIT_FOR_READY=true

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

Scale worker nodes in a Kubernetes cluster managed by Cluster API.

OPTIONS:
    -n, --name CLUSTER_NAME     Name of the cluster to scale (required)
    -w, --workers COUNT         Number of worker nodes (required)
    -ns, --namespace NAMESPACE  Kubernetes namespace (default: default)
    --no-wait                   Don't wait for scaling to complete
    -h, --help                  Show this help message

EXAMPLES:
    # Scale to 5 worker nodes
    $0 --name my-cluster --workers 5

    # Scale down to 2 workers without waiting
    $0 --name my-cluster --workers 2 --no-wait

    # Scale cluster in specific namespace
    $0 --name my-cluster --workers 3 --namespace production
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -w|--workers)
                WORKER_COUNT="$2"
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

    if [[ -z "$WORKER_COUNT" ]]; then
        log_error "Worker count is required. Use --workers to specify."
    fi

    if ! [[ "$WORKER_COUNT" =~ ^[0-9]+$ ]] || [[ "$WORKER_COUNT" -lt 0 ]]; then
        log_error "Worker count must be a non-negative integer."
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
    
    # Check if cluster is ready
    local cluster_phase
    cluster_phase=$(kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    
    if [[ "$cluster_phase" != "Provisioned" ]]; then
        log_warn "Cluster is not in 'Provisioned' state. Current phase: $cluster_phase"
        log_warn "Scaling may not work correctly if cluster is not ready."
    fi
    
    log_info "Prerequisites check completed."
}

display_current_status() {
    log_step "Current Cluster Status"
    
    echo ""
    echo "Cluster: $CLUSTER_NAME"
    echo "Namespace: $NAMESPACE"
    echo ""
    
    # Show cluster status
    echo "Cluster Status:"
    kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" -o wide
    echo ""
    
    # Show current worker deployment
    local machine_deployment="${CLUSTER_NAME}-workers"
    if kubectl get machinedeployment "$machine_deployment" -n "$NAMESPACE" &> /dev/null; then
        echo "Current Worker Deployment:"
        kubectl get machinedeployment "$machine_deployment" -n "$NAMESPACE" -o wide
        echo ""
        
        # Show current machines
        echo "Current Machines:"
        kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" -o wide
        echo ""
    else
        log_warn "Worker MachineDeployment '$machine_deployment' not found."
    fi
}

get_current_worker_count() {
    local machine_deployment="${CLUSTER_NAME}-workers"
    local current_replicas
    
    current_replicas=$(kubectl get machinedeployment "$machine_deployment" -n "$NAMESPACE" \
        -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    echo "$current_replicas"
}

scale_worker_deployment() {
    log_step "Scaling worker deployment..."
    
    local machine_deployment="${CLUSTER_NAME}-workers"
    local current_count
    current_count=$(get_current_worker_count)
    
    echo "Current worker count: $current_count"
    echo "Target worker count: $WORKER_COUNT"
    echo ""
    
    if [[ "$current_count" == "$WORKER_COUNT" ]]; then
        log_info "Cluster already has $WORKER_COUNT workers. No scaling needed."
        return
    fi
    
    if [[ "$WORKER_COUNT" -gt "$current_count" ]]; then
        log_info "Scaling UP from $current_count to $WORKER_COUNT workers..."
    else
        log_info "Scaling DOWN from $current_count to $WORKER_COUNT workers..."
    fi
    
    # Scale the MachineDeployment
    kubectl scale machinedeployment "$machine_deployment" \
        -n "$NAMESPACE" \
        --replicas="$WORKER_COUNT"
    
    log_info "Scaling command issued successfully."
}

wait_for_scaling() {
    if [[ "$WAIT_FOR_READY" != "true" ]]; then
        log_info "Skipping wait for scaling completion."
        return
    fi
    
    log_step "Waiting for scaling to complete..."
    
    local machine_deployment="${CLUSTER_NAME}-workers"
    local timeout=1200  # 20 minutes
    local elapsed=0
    local interval=10
    
    while true; do
        local current_replicas ready_replicas
        current_replicas=$(kubectl get machinedeployment "$machine_deployment" -n "$NAMESPACE" \
            -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
        ready_replicas=$(kubectl get machinedeployment "$machine_deployment" -n "$NAMESPACE" \
            -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        
        echo "Replicas: $ready_replicas/$current_replicas ready"
        
        if [[ "$ready_replicas" == "$WORKER_COUNT" ]] && [[ "$current_replicas" == "$WORKER_COUNT" ]]; then
            echo ""
            log_info "Scaling completed successfully!"
            break
        fi
        
        if [[ $elapsed -ge $timeout ]]; then
            echo ""
            log_warn "Timeout waiting for scaling to complete."
            log_warn "Current status: $ready_replicas/$current_replicas ready"
            break
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
}

verify_cluster_health() {
    log_step "Verifying cluster health..."
    
    local kubeconfig_file="$HOME/.kube/config-${CLUSTER_NAME}"
    
    if [[ ! -f "$kubeconfig_file" ]]; then
        log_warn "Kubeconfig not found at $kubeconfig_file. Cannot verify cluster health."
        return
    fi
    
    # Check if all nodes are ready
    log_info "Checking node status..."
    kubectl --kubeconfig="$kubeconfig_file" get nodes -o wide
    echo ""
    
    # Check for any issues with nodes
    local not_ready_nodes
    not_ready_nodes=$(kubectl --kubeconfig="$kubeconfig_file" get nodes \
        --no-headers 2>/dev/null | awk '$2 != "Ready" {print $1}' || echo "")
    
    if [[ -n "$not_ready_nodes" ]]; then
        log_warn "Found nodes that are not ready:"
        for node in $not_ready_nodes; do
            echo "  - $node"
        done
        echo ""
    else
        log_info "All nodes are ready."
    fi
    
    # Show pod distribution across nodes
    log_info "Pod distribution across nodes:"
    kubectl --kubeconfig="$kubeconfig_file" get pods -A -o wide \
        --field-selector=status.phase=Running 2>/dev/null | \
        awk 'NR>1 {print $8}' | sort | uniq -c | sort -nr || true
}

display_scaling_summary() {
    log_step "Scaling Summary"
    
    local machine_deployment="${CLUSTER_NAME}-workers"
    local final_count
    final_count=$(get_current_worker_count)
    
    echo ""
    echo "=========================================="
    echo "Cluster Scaling Summary"
    echo "=========================================="
    echo ""
    echo "Cluster: $CLUSTER_NAME"
    echo "Final worker count: $final_count"
    echo "Target worker count: $WORKER_COUNT"
    echo ""
    
    if [[ "$final_count" == "$WORKER_COUNT" ]]; then
        echo "✅ Scaling completed successfully!"
    else
        echo "⚠️  Scaling may not be fully complete."
        echo "   Check cluster status for more details."
    fi
    echo ""
    
    echo "Current machine status:"
    kubectl get machines -l cluster.x-k8s.io/cluster-name="$CLUSTER_NAME" -n "$NAMESPACE" -o wide
    echo ""
    
    echo "To monitor the cluster:"
    echo "  kubectl get machinedeployment ${machine_deployment} -n $NAMESPACE -w"
    echo ""
    echo "To check node status:"
    echo "  export KUBECONFIG=$HOME/.kube/config-${CLUSTER_NAME}"
    echo "  kubectl get nodes"
}

main() {
    echo "=========================================="
    echo "CAPI Cluster Scaling"
    echo "=========================================="
    echo ""
    
    parse_arguments "$@"
    check_prerequisites
    display_current_status
    scale_worker_deployment
    wait_for_scaling
    verify_cluster_health
    display_scaling_summary
    
    log_info "Cluster scaling operation completed!"
}

# Run main function
main "$@"