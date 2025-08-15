# 🚀 Automatic Startup Configuration

This document explains how the GitHub Actions Runner setup is configured to start automatically after system reboot.

## ✅ Configured Components

### 1. Docker Desktop
- **Status**: ✅ Configured for automatic startup
- **Service**: `docker-desktop.service` (systemd user service)
- **Command**: `systemctl --user enable docker-desktop`
- **Configuration**: `~/.docker/desktop/settings-store.json` → `"AutoStart": true`

### 2. Kubernetes
- **Status**: ✅ Enabled with Docker Desktop
- **Configuration**: `~/.docker/desktop/settings-store.json` → `"KubernetesEnabled": true`
- **Startup**: Automatically starts with Docker Desktop

### 3. Terraform State Files
- **Status**: ✅ Persistent local storage
- **Infrastructure**: `/home/rainforest/rainforest-devops/1-infrastructure/infrastructure.tfstate`
- **Runners**: `/home/rainforest/rainforest-devops/2-runners/runners.tfstate`
- **Backup**: `.tfstate.backup` files maintained automatically

### 4. GitHub Actions Runner Controller (ARC)
- **Status**: ✅ Deployed via Helm charts, persisted in Kubernetes
- **Components**:
  - cert-manager (SSL certificate management)
  - ARC controller (GitHub integration)
  - Runner scale sets (8am-tech organization)

## 🔄 Startup Sequence

After system reboot, the following happens automatically:

1. **System Boot** → Linux starts systemd services
2. **User Login** → systemd user services activate
3. **Docker Desktop** → Starts automatically (`AutoStart: true`)
4. **Kubernetes** → Starts with Docker Desktop (`KubernetesEnabled: true`)
5. **Helm Charts** → Kubernetes restores all deployed charts
6. **ARC Controller** → Connects to GitHub using stored PAT
7. **Ready** → Runners scale on-demand when workflows trigger

## 📋 Verification Commands

### Quick Check
```bash
# Run the automated verification script
./scripts/verify-startup.sh
```

### Manual Verification
```bash
# 1. Check Docker Desktop
systemctl --user status docker-desktop

# 2. Check Kubernetes
kubectl cluster-info

# 3. Check namespaces
kubectl get namespaces

# 4. Check infrastructure pods
kubectl get pods -n cert-manager
kubectl get pods -n actions-runner-system

# 5. Check runner configuration
kubectl get autoscalingrunnersets -n github-runners

# 6. Check Helm releases
helm list --all-namespaces
```

## ⚡ Expected Behavior

### At System Startup
- ✅ Docker Desktop starts automatically
- ✅ Kubernetes cluster becomes available
- ✅ cert-manager pods start and reach "Running" status
- ✅ ARC controller starts and connects to GitHub
- ✅ Runner scale set is configured (no pods running - minRunners=0)

### When GitHub Workflow Triggers
1. GitHub sends webhook to ARC controller
2. ARC controller creates ephemeral runner pod
3. Runner executes the workflow job
4. Runner pod terminates after job completion
5. System returns to idle state (no runner pods)

## 🔧 Troubleshooting

### If Docker Desktop doesn't start:
```bash
# Check status
systemctl --user status docker-desktop

# Start manually
systemctl --user start docker-desktop

# Re-enable auto-start
systemctl --user enable docker-desktop
```

### If Kubernetes isn't available:
```bash
# Check Docker Desktop settings
cat ~/.docker/desktop/settings-store.json | grep -E "AutoStart|KubernetesEnabled"

# Should show:
# "AutoStart": true
# "KubernetesEnabled": true
```

### If ARC components are missing:
```bash
# Check if Terraform state exists
ls -la 1-infrastructure/infrastructure.tfstate
ls -la 2-runners/runners.tfstate

# If state exists but pods missing, re-apply:
cd 1-infrastructure
export TF_VAR_github_token="your_pat_here"
terraform apply

cd ../2-runners
terraform apply
```

## 📝 Configuration Files

- **Docker Desktop**: `~/.docker/desktop/settings-store.json`
- **Systemd Service**: `/usr/lib/systemd/user/docker-desktop.service`
- **Kubernetes Config**: `~/.kube/config`
- **Terraform States**: `**/terraform.tfstate`

## 🎯 Recovery After Reboot

The setup is designed to be resilient. After any reboot:

1. **Wait 2-5 minutes** for all services to start
2. **Run verification script**: `./scripts/verify-startup.sh`
3. **Check GitHub**: Go to https://github.com/organizations/8am-tech/settings/actions/runners
4. **Test with workflow**: Trigger a workflow using `runs-on: self-hosted`

The runners will appear "Offline" in GitHub until a workflow triggers them, which is normal behavior with `minRunners=0`.