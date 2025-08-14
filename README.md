# GitHub Actions Runner Controller on Kubernetes

A production-ready, two-stage Terraform deployment for GitHub Actions self-hosted runners using the official GitHub Actions Runner Controller.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────────┐
│  Stage 1        │    │  Stage 2           │
│  Infrastructure │ -> │  GitHub Runners    │
│                 │    │                    │
│ • Cert-Manager  │    │ • RunnerScaleSets  │
│ • ARC Controller│    │ • Auto-scaling     │
│ • GitHub Secret │    │ • Organization     │
└─────────────────┘    └─────────────────────┘
```

**Benefits:**
- 🔐 **Secure**: GitHub PAT stored in Kubernetes secrets
- 📈 **Auto-scaling**: Runners scale based on workflow demand
- 🔄 **Reliable**: Two-stage deployment prevents race conditions
- 🛠️ **Production-ready**: Official GitHub ARC with proper resource limits
- ⚡ **Modern**: Uses latest RunnerScaleSet architecture

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster with kubectl configured
- Terraform >= 1.0
- GitHub Personal Access Token

### Step 1: Create GitHub PAT
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Create token with scopes:
   - **repo** (Full control of private repositories)
   - **admin:org** (Full control of orgs and teams, read and write org projects)

### Step 2: Configure Runners
```bash
# Configure your organization/repositories
vim 2-runners/terraform.tfvars
# Set: github_organizations = ["your-org"]
```

### Step 3: Deploy (Automated)
```bash
# One-command deployment
export TF_VAR_github_token="github_pat_your_token_here"
./scripts/deploy.sh --auto-approve
```

### Alternative: Manual Deployment
```bash
# Stage 1: Infrastructure
cd 1-infrastructure
export TF_VAR_github_token="github_pat_your_token_here"
terraform init && terraform apply

# Stage 2: Runners
cd ../2-runners
terraform init && terraform apply
```

## 📁 Project Structure

```
rainforest-devops/
├── 1-infrastructure/          # Stage 1: Core infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── 2-runners/                 # Stage 2: GitHub runners
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
├── modules/                   # Reusable Terraform modules
│   ├── cert-manager/          # SSL certificate management
│   ├── actions-runner-controller/  # Official GitHub ARC
│   └── github-runners/        # Runner scale sets
│
├── scripts/                   # Deployment automation
└── README.md
```

## ⚙️ Configuration

### Stage 1: Infrastructure
Environment variable (recommended):
```bash
export TF_VAR_github_token="github_pat_your_token_here"
```

### Stage 2: Runners
Edit `2-runners/terraform.tfvars`:
```hcl
# Organization-level runners (recommended)
github_organizations = ["8am-tech"]

# Or specific repositories
github_repositories = [
  "8am-tech/repo1",
  "8am-tech/repo2"
]

# Resource allocation
runner_replicas = 3
runner_resources = {
  requests = { cpu = "500m", memory = "1Gi" }
  limits   = { cpu = "2000m", memory = "4Gi" }
}

# Labels for targeting
runner_labels = ["self-hosted", "linux", "x64"]
```

## 🛠️ Scripts & Operations

### Automated Scripts
```bash
# 🚀 Deploy everything
./scripts/deploy.sh -t github_pat_xxx

# 📊 Monitor deployment
./scripts/monitor.sh status    # Overall status
./scripts/monitor.sh runners   # Runner scale sets
./scripts/monitor.sh logs      # ARC controller logs

# 🧹 Clean up resources
./scripts/cleanup.sh --force
```

### Manual Operations

#### Monitor Deployments
```bash
# Check infrastructure status
kubectl get pods -n cert-manager
kubectl get pods -n actions-runner-system

# Check runners
kubectl get pods -n github-runners
kubectl get runnerscalesets -A
```

#### View Runner Logs
```bash
kubectl logs -n actions-runner-system deployment/arc-gha-rs-controller
kubectl logs -n github-runners -l app.kubernetes.io/name=gha-runner-scale-set
```

#### Scale Runners
```bash
cd 2-runners
# Edit terraform.tfvars - change runner_replicas
terraform apply
```

## 🛡️ Security

### Secret Management
- GitHub PAT stored securely in Kubernetes secrets
- Environment variables for sensitive data during deployment
- No plaintext secrets in Terraform files

### Production Recommendations
- Use GitHub Apps instead of PATs for better security and rate limits
- Enable audit logging
- Set up proper RBAC for runner pods
- Use private container registry for runner images
- Implement network policies

## 🚨 Troubleshooting

### Common Issues

**1. Runners Not Appearing in GitHub**
```bash
# Check runner scale set status
kubectl get runnerscalesets -A
kubectl describe runnerscaleset -n github-runners

# Verify GitHub token permissions
# Token needs: repo, admin:org scopes
```

**2. Scale Set Controller Issues**
```bash
# Check ARC controller logs
kubectl logs -n actions-runner-system deployment/arc-gha-rs-controller

# Verify controller is running
kubectl get pods -n actions-runner-system
```

**3. Resource Limits**
```bash
# Check resource usage
kubectl top pods -n github-runners

# Adjust runner_resources in terraform.tfvars
```

**4. Helm Chart Issues**
```bash
# Check Helm releases
helm list -A

# If deployment fails, check values
helm get values arc-runner-set-8am-tech -n github-runners
```

## 🔄 Updates and Maintenance

### Update ARC Version
```bash
cd 1-infrastructure
# Edit modules/actions-runner-controller/main.tf - update version
terraform plan
terraform apply
```

### Update Runner Image
```bash
cd 2-runners
# Edit terraform.tfvars - update runner_image
terraform apply
```

### Clean Deployment (if needed)
```bash
# Destroy runners first, then infrastructure
cd 2-runners && terraform destroy
cd ../1-infrastructure && terraform destroy
```

## 📊 GitHub Integration

### Verify Runners
1. Go to your GitHub organization: `https://github.com/organizations/YOUR_ORG/settings/actions/runners`
2. You should see self-hosted runners listed as "Idle"
3. Runners will automatically start when workflows are queued

### Using Runners in Workflows
```yaml
name: CI
on: [push]
jobs:
  test:
    runs-on: self-hosted  # Uses your ARC runners
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on self-hosted runner!"
```

## 🎯 Architecture Notes

### Official GitHub ARC vs Legacy
This setup uses the **official GitHub Actions Runner Controller** with:
- RunnerScaleSets (new) instead of RunnerDeployments (legacy)
- Direct GitHub API integration
- Improved auto-scaling and efficiency
- Better resource management

### Two-Stage Benefits
1. **Stage 1**: Deploys core infrastructure (cert-manager, ARC controller)
2. **Stage 2**: Deploys runner scale sets that depend on Stage 1

This prevents race conditions and allows independent updates.

## 🚀 Next Steps

1. **Multi-Organization**: Add more organizations to `github_organizations`
2. **Advanced Scaling**: Configure custom scaling metrics
3. **CI/CD Pipeline**: Automate infrastructure updates
4. **Monitoring**: Add Prometheus/Grafana for runner metrics
5. **GitHub Apps**: Migrate from PAT to GitHub App authentication