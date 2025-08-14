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

log() {
    echo -e "${GREEN}[SECURITY] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

check_git_history() {
    log "Checking git history for PAT exposure..."
    
    cd "$PROJECT_ROOT"
    
    # Check for real PAT patterns in git history
    local pat_count
    pat_count=$(git log --all --full-history --grep="github_pat_[a-zA-Z0-9]{36}" --grep="ghp_[a-zA-Z0-9]{36}" | wc -l)
    
    if [[ $pat_count -gt 0 ]]; then
        error "Found potential PAT patterns in git history!"
        git log --all --full-history --grep="github_pat" --grep="ghp_" --oneline
        return 1
    fi
    
    # Check commit messages and diffs
    if git log --all --full-history -p | grep -E "github_pat_[a-zA-Z0-9]{36}|ghp_[a-zA-Z0-9]{36}" >/dev/null 2>&1; then
        error "Found real PAT patterns in git diffs!"
        return 1
    fi
    
    info "✅ Git history is clean"
}

check_working_directory() {
    log "Checking working directory for PAT exposure..."
    
    cd "$PROJECT_ROOT"
    
    # Check for real PATs in committed files
    if find . -name "*.tf" -o -name "*.md" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" | \
       xargs grep -E "github_pat_[a-zA-Z0-9]{36}|ghp_[a-zA-Z0-9]{36}" 2>/dev/null; then
        error "Found real PAT patterns in working directory!"
        return 1
    fi
    
    info "✅ Working directory is clean"
}

check_environment() {
    log "Checking environment variables..."
    
    # Don't expose the actual values, just check if they exist
    if env | grep -i "github" >/dev/null 2>&1; then
        warn "GitHub environment variables detected"
        env | grep -i "github" | sed 's/=.*/=***REDACTED***/'
    else
        info "✅ No GitHub environment variables"
    fi
}

check_gitignore() {
    log "Checking .gitignore configuration..."
    
    cd "$PROJECT_ROOT"
    
    # Test gitignore patterns
    local test_files=("terraform.tfvars.local" ".env" "test.tfstate" ".terraform/")
    local ignored_count=0
    
    for file in "${test_files[@]}"; do
        if git check-ignore "$file" >/dev/null 2>&1; then
            ((ignored_count++))
        else
            warn "$file is not ignored by git"
        fi
    done
    
    if [[ $ignored_count -eq ${#test_files[@]} ]]; then
        info "✅ All sensitive file patterns are git-ignored"
    else
        warn "Some sensitive files may not be properly ignored"
    fi
}

check_state_files() {
    log "Checking Terraform state files..."
    
    cd "$PROJECT_ROOT"
    
    # Find state files
    local state_files
    state_files=$(find . -name "*.tfstate*" -type f)
    
    if [[ -n "$state_files" ]]; then
        info "Found state files (should be git-ignored):"
        echo "$state_files"
        
        # Verify they're git-ignored
        while IFS= read -r file; do
            if git check-ignore "$file" >/dev/null 2>&1; then
                info "✅ $file is git-ignored"
            else
                error "❌ $file is NOT git-ignored!"
                return 1
            fi
        done <<< "$state_files"
    else
        info "No state files found"
    fi
}

validate_pat_format() {
    log "Validating PAT format in examples..."
    
    cd "$PROJECT_ROOT"
    
    # Check that example files only contain placeholder PATs
    local example_files
    example_files=$(find . -name "*.example" -o -name "*.md" -o -name "*.sh")
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Look for PAT patterns that are NOT placeholders
            if grep -E "github_pat_[a-zA-Z0-9]{36}|ghp_[a-zA-Z0-9]{36}" "$file" >/dev/null 2>&1; then
                error "Found real PAT in example file: $file"
                return 1
            fi
            
            # Verify placeholder patterns exist
            if grep -E "github_pat_.*your.*token|github_pat_xxx" "$file" >/dev/null 2>&1; then
                info "✅ $file contains placeholder PAT"
            fi
        fi
    done <<< "$example_files"
}

security_recommendations() {
    log "Security Recommendations:"
    echo ""
    info "✅ GOOD PRACTICES:"
    echo "  • Use environment variables: export TF_VAR_github_token=\"your_pat\""
    echo "  • Rotate PATs every 90 days"
    echo "  • Use minimal required scopes (repo, admin:org)"
    echo "  • Enable 2FA on GitHub account"
    echo "  • Monitor GitHub audit logs"
    echo ""
    info "🚫 AVOID:"
    echo "  • Committing PATs to git"
    echo "  • Storing PATs in files"
    echo "  • Using PATs in shell history"
    echo "  • Sharing state files publicly"
}

main() {
    log "Starting security audit for GitHub PAT exposure..."
    echo ""
    
    local checks_passed=0
    local total_checks=6
    
    # Run all checks
    check_git_history && ((checks_passed++))
    check_working_directory && ((checks_passed++))
    check_environment && ((checks_passed++))
    check_gitignore && ((checks_passed++))
    check_state_files && ((checks_passed++))
    validate_pat_format && ((checks_passed++))
    
    echo ""
    log "Security Audit Results: $checks_passed/$total_checks checks passed"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        log "🛡️  SECURITY STATUS: GOOD"
        info "No PAT exposure detected!"
    else
        error "🚨 SECURITY ISSUES DETECTED!"
        error "Please review and fix the issues above"
        return 1
    fi
    
    echo ""
    security_recommendations
}

# Run main function
main "$@"