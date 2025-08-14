#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Monitor GitHub Actions Runner Controller deployment"
    echo ""
    echo "Commands:"
    echo "  status      Show overall deployment status (default)"
    echo "  pods        Show all pods in relevant namespaces"
    echo "  logs        Show logs from ARC controller"
    echo "  runners     Show runner scale sets status"
    echo "  events      Show recent events"
    echo "  resources   Show resource usage"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs"
    echo "  $0 runners"
}

log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

show_status() {
    log "GitHub Actions Runner Controller Status"
    echo ""
    
    # Check namespaces
    info "=== Namespaces ==="
    local namespaces=("cert-manager" "actions-runner-system" "github-runners")
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            echo -e "  ✅ $ns"
        else
            echo -e "  ❌ $ns (missing)"
        fi
    done
    echo ""
    
    # Check deployments
    info "=== Deployments ==="
    
    # cert-manager
    if kubectl get deployment -n cert-manager >/dev/null 2>&1; then
        echo "📦 cert-manager:"
        kubectl get deployment -n cert-manager -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas,UP-TO-DATE:.status.updatedReplicas
    fi
    echo ""
    
    # ARC controller
    if kubectl get deployment -n actions-runner-system >/dev/null 2>&1; then
        echo "🎮 ARC Controller:"
        kubectl get deployment -n actions-runner-system -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas,UP-TO-DATE:.status.updatedReplicas
    fi
    echo ""
    
    # Runner scale sets
    if kubectl get ns github-runners >/dev/null 2>&1; then
        show_runners
    else
        warn "github-runners namespace not found"
    fi
}

show_pods() {
    log "All Pods Status"
    echo ""
    
    local namespaces=("cert-manager" "actions-runner-system" "github-runners")
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            info "=== Namespace: $ns ==="
            kubectl get pods -n "$ns" -o wide || echo "  No pods found"
            echo ""
        fi
    done
}

show_logs() {
    log "ARC Controller Logs"
    echo ""
    
    if kubectl get deployment -n actions-runner-system arc-gha-rs-controller >/dev/null 2>&1; then
        kubectl logs -n actions-runner-system deployment/arc-gha-rs-controller --tail=50 --follow=false
    else
        error "ARC controller not found"
    fi
}

show_runners() {
    info "=== Runner Scale Sets ==="
    
    # Check for Helm releases (runner scale sets)
    if command -v helm >/dev/null 2>&1; then
        echo "🏃 Runner Scale Sets (Helm):"
        helm list -n github-runners 2>/dev/null || echo "  No runner scale sets found"
        echo ""
    fi
    
    # Check for any runner pods
    if kubectl get pods -n github-runners >/dev/null 2>&1; then
        echo "🏃 Runner Pods:"
        kubectl get pods -n github-runners -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName,AGE:.metadata.creationTimestamp
        echo ""
    fi
    
    # Check for listener pods (these handle the scaling)
    if kubectl get pods -n github-runners -l app.kubernetes.io/name=gha-runner-scale-set-listener >/dev/null 2>&1; then
        echo "👂 Scale Set Listeners:"
        kubectl get pods -n github-runners -l app.kubernetes.io/name=gha-runner-scale-set-listener -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,READY:.status.containerStatuses[0].ready,AGE:.metadata.creationTimestamp
        echo ""
    fi
}

show_events() {
    log "Recent Events (last 10)"
    echo ""
    
    local namespaces=("cert-manager" "actions-runner-system" "github-runners")
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            info "=== Events in $ns ==="
            kubectl get events -n "$ns" --sort-by='.lastTimestamp' | tail -n 10 || echo "  No events found"
            echo ""
        fi
    done
}

show_resources() {
    log "Resource Usage"
    echo ""
    
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl not found"
        return 1
    fi
    
    # Check if metrics server is available
    if ! kubectl top nodes >/dev/null 2>&1; then
        warn "Metrics server not available, cannot show resource usage"
        return 0
    fi
    
    local namespaces=("cert-manager" "actions-runner-system" "github-runners")
    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" >/dev/null 2>&1; then
            info "=== Resource Usage in $ns ==="
            kubectl top pods -n "$ns" 2>/dev/null || echo "  No metrics available"
            echo ""
        fi
    done
}

main() {
    local command="${1:-status}"
    
    case "$command" in
        status)
            show_status
            ;;
        pods)
            show_pods
            ;;
        logs)
            show_logs
            ;;
        runners)
            show_runners
            ;;
        events)
            show_events
            ;;
        resources)
            show_resources
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"