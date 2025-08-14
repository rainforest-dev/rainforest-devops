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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check terraform
    if ! command -v terraform &> /dev/null; then
        log_error "terraform not found. Please install terraform."
        exit 1
    fi
    
    # Check kubernetes connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster. Please check your config."
        exit 1
    fi
    
    log_success "Prerequisites check passed!"
}

# Deploy infrastructure (Stage 1)
deploy_infrastructure() {
    log_info "Deploying infrastructure (Stage 1)..."
    
    cd 1-infrastructure
    
    # Check for config file
    if [[ ! -f "terraform.tfvars.local" ]]; then
        log_error "terraform.tfvars.local not found!"
        log_info "Please copy terraform.tfvars.example to terraform.tfvars.local and add your GitHub PAT"
        exit 1
    fi
    
    # Initialize and apply
    terraform init
    terraform plan -var-file="terraform.tfvars.local" -out=infrastructure.tfplan
    terraform apply infrastructure.tfplan
    
    cd ..
    log_success "Infrastructure deployed successfully!"
}

# Wait for infrastructure to be ready
wait_for_infrastructure() {
    log_info "Waiting for infrastructure to be ready..."
    
    # Wait for Vault
    log_info "Waiting for Vault..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=300s
    
    # Wait for cert-manager
    log_info "Waiting for cert-manager..."
    kubectl wait --for=condition=Ready pod -l app=cert-manager -n cert-manager --timeout=300s
    
    # Wait for ARC
    log_info "Waiting for Actions Runner Controller..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=actions-runner-controller -n actions-runner-system --timeout=300s
    
    # Wait for CRDs
    log_info "Waiting for CRDs to be established..."
    kubectl wait --for=condition=Established crd/runnerdeployments.actions.github.com --timeout=300s
    
    log_success "Infrastructure is ready!"
}

# Deploy runners (Stage 2)
deploy_runners() {
    log_info "Deploying GitHub runners (Stage 2)..."
    
    cd 2-runners
    
    # Initialize and apply
    terraform init
    terraform plan -out=runners.tfplan
    terraform apply runners.tfplan
    
    cd ..
    log_success "GitHub runners deployed successfully!"
}

# Main deployment flow
main() {
    log_info "Starting GitHub Actions Runner Controller deployment..."
    
    check_prerequisites
    deploy_infrastructure
    wait_for_infrastructure
    deploy_runners
    
    log_success "🎉 Deployment completed successfully!"
    log_info "Next steps:"
    echo "  1. Check runner status: kubectl get pods -n github-runners"
    echo "  2. View runner logs: kubectl logs -n github-runners -l app=runner"
    echo "  3. Check GitHub repository settings for new self-hosted runners"
}

# Run main function
main "$@"