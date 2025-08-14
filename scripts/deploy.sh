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
GITHUB_TOKEN=""
SKIP_INFRASTRUCTURE=false
SKIP_RUNNERS=false
AUTO_APPROVE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy GitHub Actions Runner Controller on Kubernetes"
    echo ""
    echo "Options:"
    echo "  -t, --token TOKEN     GitHub Personal Access Token (required)"
    echo "  --skip-infrastructure Skip Stage 1 (infrastructure) deployment"
    echo "  --skip-runners       Skip Stage 2 (runners) deployment"
    echo "  --auto-approve       Auto-approve Terraform plans"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  TF_VAR_github_token  GitHub token (alternative to -t)"
    echo ""
    echo "Examples:"
    echo "  $0 -t github_pat_xxx"
    echo "  $0 --token github_pat_xxx --auto-approve"
    echo "  $0 --skip-infrastructure --token github_pat_xxx"
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

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl is required but not installed"
    fi
    
    # Check terraform
    if ! command -v terraform >/dev/null 2>&1; then
        error "terraform is required but not installed"
    fi
    
    # Check kubernetes connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "Cannot connect to Kubernetes cluster. Please check your kubeconfig"
    fi
    
    # Check terraform version
    local tf_version
    tf_version=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
    info "Using Terraform version: $tf_version"
    
    # Check kubernetes cluster info
    local cluster_info
    cluster_info=$(kubectl cluster-info | head -1)
    info "Connected to: $cluster_info"
}

validate_github_token() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        if [[ -n "${TF_VAR_github_token:-}" ]]; then
            GITHUB_TOKEN="$TF_VAR_github_token"
        else
            error "GitHub token is required. Use -t or set TF_VAR_github_token"
        fi
    fi
    
    log "Validating GitHub token..."
    
    # Basic token format check
    if [[ ! "$GITHUB_TOKEN" =~ ^github_pat_ ]] && [[ ! "$GITHUB_TOKEN" =~ ^ghp_ ]]; then
        warn "Token doesn't match expected GitHub PAT format"
    fi
}

deploy_infrastructure() {
    if [[ "$SKIP_INFRASTRUCTURE" == "true" ]]; then
        info "Skipping infrastructure deployment"
        return
    fi
    
    log "Deploying Stage 1: Infrastructure..."
    
    cd "$PROJECT_ROOT/1-infrastructure"
    
    # Initialize terraform
    log "Initializing Terraform..."
    terraform init
    
    # Export token for terraform
    export TF_VAR_github_token="$GITHUB_TOKEN"
    
    # Plan
    log "Planning infrastructure changes..."
    terraform plan
    
    # Apply
    if [[ "$AUTO_APPROVE" == "true" ]]; then
        log "Applying infrastructure changes (auto-approved)..."
        terraform apply -auto-approve
    else
        log "Applying infrastructure changes..."
        terraform apply
    fi
    
    log "Infrastructure deployment completed successfully!"
}

deploy_runners() {
    if [[ "$SKIP_RUNNERS" == "true" ]]; then
        info "Skipping runners deployment"
        return
    fi
    
    log "Deploying Stage 2: GitHub Runners..."
    
    cd "$PROJECT_ROOT/2-runners"
    
    # Check if terraform.tfvars exists
    if [[ ! -f "terraform.tfvars" ]]; then
        warn "terraform.tfvars not found. Please configure your organization/repositories."
        info "Example configuration:"
        info "github_organizations = [\"your-org\"]"
        info "runner_replicas = 3"
        error "Please create terraform.tfvars before running deployment"
    fi
    
    # Initialize terraform
    log "Initializing Terraform..."
    terraform init -upgrade
    
    # Export token for terraform
    export TF_VAR_github_token="$GITHUB_TOKEN"
    
    # Plan
    log "Planning runners changes..."
    terraform plan
    
    # Apply
    if [[ "$AUTO_APPROVE" == "true" ]]; then
        log "Applying runners changes (auto-approved)..."
        terraform apply -auto-approve
    else
        log "Applying runners changes..."
        terraform apply
    fi
    
    log "Runners deployment completed successfully!"
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Check infrastructure pods
    log "Checking infrastructure components..."
    kubectl get pods -n cert-manager --no-headers | while read -r line; do
        info "cert-manager: $line"
    done
    
    kubectl get pods -n actions-runner-system --no-headers | while read -r line; do
        info "ARC controller: $line"
    done
    
    # Check runner scale sets
    if kubectl get ns github-runners >/dev/null 2>&1; then
        log "Checking runner scale sets..."
        kubectl get pods -n github-runners --no-headers | while read -r line; do
            info "Runners: $line"
        done
        
        # Check if any runner scale sets exist
        if kubectl get runnerscalesets -A >/dev/null 2>&1; then
            kubectl get runnerscalesets -A --no-headers | while read -r line; do
                info "RunnerScaleSet: $line"
            done
        fi
    fi
    
    log "Deployment verification completed!"
    info ""
    info "Next steps:"
    info "1. Check your GitHub organization settings for self-hosted runners"
    info "2. Create a workflow that uses 'runs-on: self-hosted'"
    info "3. Monitor runner pods: kubectl get pods -n github-runners"
}

cleanup() {
    # Cleanup function for interrupted deployments
    warn "Deployment interrupted. Current state preserved."
    info "To resume: run the same command again"
    info "To clean up: cd to 1-infrastructure or 2-runners and run 'terraform destroy'"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --skip-infrastructure)
                SKIP_INFRASTRUCTURE=true
                shift
                ;;
            --skip-runners)
                SKIP_RUNNERS=true
                shift
                ;;
            --auto-approve)
                AUTO_APPROVE=true
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
    
    # Set trap for cleanup
    trap cleanup INT TERM
    
    log "Starting GitHub Actions Runner Controller deployment..."
    
    check_prerequisites
    validate_github_token
    deploy_infrastructure
    deploy_runners
    verify_deployment
    
    log "🎉 Deployment completed successfully!"
    info ""
    info "Your GitHub Actions runners are now ready!"
    info "Visit: https://github.com/organizations/YOUR_ORG/settings/actions/runners"
}

# Run main function
main "$@"