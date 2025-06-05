#!/bin/bash
set -euo pipefail

# Bootstrap script for Kubernetes cluster deployment
# This script orchestrates the complete K8s cluster creation process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$PROJECT_ROOT/terraform/proxmox"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
K8S_INVENTORY="$ANSIBLE_DIR/inventory/k8s/hosts.ini"

# Functions
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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found. Please install Terraform first."
    fi
    
    # Check Ansible
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible not found. Please install Ansible first."
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_warn "kubectl not found. Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Check for required files
    if [ ! -f "$TERRAFORM_DIR/creds.auto.tfvars" ]; then
        log_error "Terraform credentials file not found at $TERRAFORM_DIR/creds.auto.tfvars"
    fi
    
    if [ ! -f "$HOME/.ansible-vault/vault.secret" ]; then
        log_error "Ansible vault password file not found at $HOME/.ansible-vault/vault.secret"
    fi
    
    log_info "Prerequisites check completed."
}

deploy_infrastructure() {
    log_info "Deploying K8s infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Plan the deployment
    log_info "Running Terraform plan..."
    terraform plan -out=k8s-cluster.tfplan
    
    # Apply the deployment
    read -p "Do you want to apply the Terraform plan? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        terraform apply k8s-cluster.tfplan
        
        # Extract MAC addresses and update vars.auto.tfvars
        log_info "Extracting MAC addresses..."
        terraform output -json | jq -r '
            .k8s_control_plane_ips.value | to_entries[] | 
            "# \(.key) MAC: \(.value.macaddr)"
        '
        
        log_warn "Remember to update vars.auto.tfvars with the MAC addresses above!"
    else
        log_info "Terraform apply cancelled."
        exit 0
    fi
    
    cd - > /dev/null
}

wait_for_nodes() {
    log_info "Waiting for nodes to be ready..."
    
    # Extract IPs from inventory
    local nodes=($(grep -E "ansible_host=" "$K8S_INVENTORY" | awk -F'=' '{print $2}'))
    
    for node in "${nodes[@]}"; do
        log_info "Waiting for $node to be accessible..."
        while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no techdufus@"$node" "exit" &> /dev/null; do
            echo -n "."
            sleep 5
        done
        echo " Ready!"
    done
    
    log_info "All nodes are accessible."
}

configure_cluster() {
    log_info "Configuring Kubernetes cluster with Ansible..."
    
    cd "$ANSIBLE_DIR"
    
    # Run the k8s cluster playbook
    ansible-playbook \
        -i "$K8S_INVENTORY" \
        playbooks/k8s-cluster.yaml \
        --tags k8s
    
    cd - > /dev/null
}

deploy_argocd() {
    log_info "Deploying ArgoCD..."
    
    cd "$ANSIBLE_DIR"
    
    # Run ArgoCD deployment
    ansible-playbook \
        -i "$K8S_INVENTORY" \
        playbooks/k8s-cluster.yaml \
        --tags argocd
    
    cd - > /dev/null
}

get_cluster_info() {
    log_info "Retrieving cluster information..."
    
    # Get kubeconfig from control plane
    local control_plane_ip=$(grep -A1 "k8s_control_plane" "$K8S_INVENTORY" | grep "ansible_host" | head -1 | awk -F'=' '{print $2}')
    
    log_info "Copying kubeconfig from control plane..."
    scp techdufus@"$control_plane_ip":.kube/config "$HOME/.kube/config-home-k8s"
    
    export KUBECONFIG="$HOME/.kube/config-home-k8s"
    
    # Get cluster status
    kubectl cluster-info
    kubectl get nodes
    
    # Get ArgoCD password
    if kubectl get namespace argocd &> /dev/null; then
        log_info "ArgoCD admin password:"
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo
    fi
}

main() {
    log_info "Starting Kubernetes cluster bootstrap process..."
    
    check_prerequisites
    
    # Step 1: Deploy infrastructure
    read -p "Deploy K8s infrastructure with Terraform? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        deploy_infrastructure
        wait_for_nodes
    fi
    
    # Step 2: Configure cluster
    read -p "Configure Kubernetes cluster with Ansible? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        configure_cluster
    fi
    
    # Step 3: Deploy ArgoCD
    read -p "Deploy ArgoCD? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        deploy_argocd
    fi
    
    # Step 4: Get cluster information
    get_cluster_info
    
    log_info "Kubernetes cluster bootstrap completed!"
    log_info "Next steps:"
    log_info "1. Update vars.auto.tfvars with MAC addresses from Terraform output"
    log_info "2. Access ArgoCD at https://k8s-control-1.home.io:30443"
    log_info "3. Configure ArgoCD to sync from your Git repository"
}

# Run main function
main "$@"