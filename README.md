# GitHub Actions Runner Controller on Kubernetes

A production-ready, two-stage Terraform deployment for GitHub Actions self-hosted runners with HashiCorp Vault secret management.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────────┐
│  Stage 1        │    │  Stage 2           │
│  Infrastructure │ -> │  GitHub Runners    │
│                 │    │                    │
│ • Vault         │    │ • RunnerDeployment │
│ • Cert-Manager  │    │ • Autoscaling      │
│ • ARC Controller│    │ • Organization      │
└─────────────────┘    └─────────────────────┘
```

**Benefits:**
- 🔐 **Secure**: GitHub PAT stored in Vault
- 📈 **Auto-scaling**: Runners scale based on workflow queue
- 🔄 **Reliable**: Two-stage deployment prevents race conditions
- 🛠️ **Production-ready**: Proper resource limits and monitoring

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster with kubectl configured
- Terraform >= 1.0
- Helm >= 3.0
- GitHub Personal Access Token

### Step 1: Create GitHub PAT
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Create **Fine-grained token** with:
   - **Actions**: Read and Write
   - **Administration**: Write
   - **Metadata**: Read

### Step 2: Deploy Infrastructure
```bash
cd 1-infrastructure

# Create local config (git-ignored)
cp terraform.tfvars.example terraform.tfvars.local
vim terraform.tfvars.local  # Add your GitHub PAT

# Deploy
terraform init
terraform apply
```

### Step 3: Deploy Runners
```bash
cd ../2-runners

# Update configuration
vim terraform.tfvars  # Configure your org/repos

# Deploy
terraform init
terraform apply
```

## 📁 Project Structure

```
rainforest-devops/
├── 1-infrastructure/          # Stage 1: Core infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.local (create this)
│
├── 2-runners/                 # Stage 2: GitHub runners
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars
│
├── modules/                   # Reusable Terraform modules
│   ├── vault/
│   ├── cert-manager/
│   ├── actions-runner-controller/
│   └── github-runners/
│
├── scripts/                   # Deployment automation
└── README.md
```

## ⚙️ Configuration

### Stage 1: Infrastructure
Edit `1-infrastructure/terraform.tfvars.local`:
```hcl
github_token = "github_pat_your_token_here"
vault_dev_token = "dev-root-token-change-me"  # Change for production
```

### Stage 2: Runners
Edit `2-runners/terraform.tfvars`:
```hcl
# Organization-level runners (recommended)
github_organizations = ["your-org"]

# Or specific repositories
github_repositories = [
  "your-org/repo1",
  "your-org/repo2"
]

# Resource allocation
runner_replicas = 5
runner_resources = {
  requests = { cpu = "500m", memory = "1Gi" }
  limits   = { cpu = "2000m", memory = "4Gi" }
}

# Labels for targeting
runner_labels = ["self-hosted", "linux", "x64", "prod"]
```

## 🔧 Operations

### Monitor Deployments
```bash
# Check infrastructure status
kubectl get pods -n vault
kubectl get pods -n cert-manager
kubectl get pods -n actions-runner-system

# Check runners
kubectl get runnerdeployments -n github-runners
kubectl get pods -n github-runners
```

### View Runner Logs
```bash
kubectl logs -n actions-runner-system deployment/actions-runner-controller
kubectl logs -n github-runners -l app=runner
```

### Scale Runners
```bash
cd 2-runners
# Edit terraform.tfvars - change runner_replicas
terraform apply
```

### Access Vault UI (Development)
```bash
kubectl port-forward -n vault svc/vault 8200:8200
# Open http://localhost:8200 (token: dev-root-token-change-me)
```

## 🛡️ Security

### Development vs Production

**Development (current setup):**
- Vault in dev mode (in-memory storage)
- Simple authentication
- Good for testing and personal use

**Production recommendations:**
- Use Vault in HA mode with persistent storage
- Implement proper Vault unsealing
- Use GitHub Apps instead of PATs
- Enable audit logging
- Set up proper RBAC

### Secret Management
- GitHub PAT is stored securely in Vault
- No plaintext secrets in Terraform files
- Environment variables for sensitive data
- `.local` files are git-ignored

## 🚨 Troubleshooting

### Common Issues

**1. CRD Not Found**
```bash
# Check if ARC is deployed
kubectl get crd runnerdeployments.actions.github.com
# If missing, redeploy stage 1
```

**2. Runners Not Registering**
```bash
# Check GitHub PAT permissions
kubectl get secret -n actions-runner-system github-token-vault -o yaml
# Verify PAT has admin:org and repo permissions
```

**3. Vault Connection Issues**
```bash
# Check Vault status
kubectl get pods -n vault
kubectl port-forward -n vault svc/vault 8200:8200
```

**4. Resource Limits**
```bash
# Check resource usage
kubectl top pods -n github-runners
# Adjust runner_resources in terraform.tfvars
```

## 🔄 Updates and Maintenance

### Update ARC Version
```bash
cd 1-infrastructure
# Edit main.tf - update version in actions-runner-controller module
terraform plan
terraform apply
```

### Update Runner Image
```bash
cd 2-runners
# Edit terraform.tfvars - update runner_image
terraform apply
```

### Backup State Files
```bash
# Both stages use local backend
cp 1-infrastructure/infrastructure.tfstate backups/
cp 2-runners/runners.tfstate backups/
```

## 📊 Monitoring

### Key Metrics to Monitor
- Runner pod status and resource usage
- GitHub Actions queue length
- Vault secret access patterns
- Kubernetes cluster resource utilization

### Recommended Tools
- Prometheus + Grafana for metrics
- ELK stack for log aggregation
- GitHub Actions usage analytics

## 🎯 Next Steps

1. **Production Hardening**: Move to HA Vault with persistent storage
2. **CI/CD Integration**: Add pipeline for infrastructure updates  
3. **Multi-cluster**: Extend to dev/staging/prod environments
4. **Cost Optimization**: Implement spot instances for runners
5. **Advanced Scaling**: Custom metrics for more intelligent autoscaling