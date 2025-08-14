#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Confirmation prompt
confirm_destruction() {
    log_warning "This will destroy ALL GitHub runner infrastructure!"
    echo "This includes:"
    echo "  - All GitHub runner deployments"
    echo "  - Actions Runner Controller"
    echo "  - Vault instance and secrets"
    echo "  - cert-manager"
    echo ""
    read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        log_info "Destruction cancelled."
        exit 0
    fi
}

# Destroy runners (Stage 2)
destroy_runners() {
    log_info "Destroying GitHub runners (Stage 2)..."
    
    if [[ -d "2-runners" && -f "2-runners/runners.tfstate" ]]; then
        cd 2-runners
        terraform destroy -auto-approve
        cd ..
        log_success "GitHub runners destroyed!"
    else
        log_warning "No runners state found, skipping..."
    fi
}

# Destroy infrastructure (Stage 1)
destroy_infrastructure() {
    log_info "Destroying infrastructure (Stage 1)..."
    
    if [[ -d "1-infrastructure" && -f "1-infrastructure/infrastructure.tfstate" ]]; then
        cd 1-infrastructure
        
        if [[ -f "terraform.tfvars.local" ]]; then
            terraform destroy -var-file="terraform.tfvars.local" -auto-approve
        else
            log_warning "terraform.tfvars.local not found, using environment variables"
            terraform destroy -auto-approve
        fi
        
        cd ..
        log_success "Infrastructure destroyed!"
    else
        log_warning "No infrastructure state found, skipping..."
    fi
}

# Clean up any remaining resources
cleanup_remaining() {
    log_info "Cleaning up any remaining resources..."
    
    # Delete namespaces if they exist
    namespaces=("github-runners" "actions-runner-system" "cert-manager" "vault")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            log_info "Deleting namespace: $ns"
            kubectl delete namespace "$ns" --ignore-not-found=true
        fi
    done
    
    # Delete CRDs if they exist
    kubectl delete crd runnerdeployments.actions.github.com --ignore-not-found=true
    kubectl delete crd runnerreplicasets.actions.github.com --ignore-not-found=true
    kubectl delete crd horizontalrunnerautoscalers.actions.github.com --ignore-not-found=true
    
    log_success "Cleanup completed!"
}

# Main destruction flow
main() {
    log_info "GitHub Actions Runner Controller destruction process"
    
    confirm_destruction
    
    destroy_runners
    destroy_infrastructure
    cleanup_remaining
    
    log_success "🗑️  All resources destroyed successfully!"
    log_info "State files preserved for recovery if needed"
}

# Run main function
main "$@"