#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
FORCE=false
SKIP_CONFIRMATION=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Clean up GitHub Actions Runner Controller deployment"
    echo ""
    echo "Options:"
    echo "  --force              Skip confirmation prompts"
    echo "  --skip-confirmation  Skip the initial confirmation"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "This will destroy:"
    echo "  - All GitHub runner scale sets"
    echo "  - ARC controller"
    echo "  - cert-manager"
    echo "  - All associated Kubernetes resources"
}

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

confirm() {
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    local prompt="$1"
    echo -e "${YELLOW}$prompt (y/N): ${NC}"
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

cleanup_runners() {
    log "Cleaning up GitHub runners (Stage 2)..."
    
    cd "$PROJECT_ROOT/2-runners"
    
    if [[ ! -f "runners.tfstate" ]]; then
        info "No runners state file found, skipping runners cleanup"
        return
    fi
    
    if confirm "Destroy all GitHub runner scale sets?"; then
        terraform destroy -auto-approve
        log "Runners cleanup completed"
    else
        warn "Skipping runners cleanup"
    fi
}

cleanup_infrastructure() {
    log "Cleaning up infrastructure (Stage 1)..."
    
    cd "$PROJECT_ROOT/1-infrastructure"
    
    if [[ ! -f "infrastructure.tfstate" ]]; then
        info "No infrastructure state file found, skipping infrastructure cleanup"
        return
    fi
    
    if confirm "Destroy ARC controller and cert-manager?"; then
        terraform destroy -auto-approve
        log "Infrastructure cleanup completed"
    else
        warn "Skipping infrastructure cleanup"
    fi
}

verify_cleanup() {
    log "Verifying cleanup..."
    
    # Check for remaining resources
    local namespaces=("github-runners" "actions-runner-system" "cert-manager")
    
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            warn "Namespace $ns still exists"
            kubectl get pods -n "$ns" 2>/dev/null || true
        else
            info "Namespace $ns successfully removed"
        fi
    done
    
    # Check for CRDs
    if kubectl get crd | grep -E "(actions\.|cert-manager)" >/dev/null 2>&1; then
        warn "Some CRDs may still exist:"
        kubectl get crd | grep -E "(actions\.|cert-manager)" || true
    else
        info "All related CRDs removed"
    fi
    
    log "Cleanup verification completed"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                FORCE=true
                shift
                ;;
            --skip-confirmation)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    log "Starting cleanup of GitHub Actions Runner Controller deployment..."
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo -e "${RED}WARNING: This will destroy all deployed resources!${NC}"
        echo ""
        echo "Resources to be destroyed:"
        echo "  • GitHub runner scale sets"
        echo "  • Actions Runner Controller"
        echo "  • cert-manager"
        echo "  • All Kubernetes secrets and configmaps"
        echo ""
        
        if ! confirm "Are you sure you want to proceed?"; then
            info "Cleanup cancelled"
            exit 0
        fi
    fi
    
    cleanup_runners
    cleanup_infrastructure
    verify_cleanup
    
    log "🧹 Cleanup completed successfully!"
    info ""
    info "All GitHub Actions Runner Controller resources have been removed."
    info "Your Kubernetes cluster is now clean."
}

# Run main function
main "$@"