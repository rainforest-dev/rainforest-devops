#!/bin/bash
# Verify GitHub Actions Runner setup after system reboot

set -e

echo "🔍 Verifying GitHub Actions Runner setup after reboot..."
echo "=================================================="

# Function to wait for a condition with timeout
wait_for_condition() {
    local condition="$1"
    local description="$2"
    local timeout=300 # 5 minutes
    local interval=10
    local elapsed=0
    
    echo "⏳ Waiting for: $description"
    
    while ! eval "$condition" && [ $elapsed -lt $timeout ]; do
        echo "   ... waiting ($elapsed/${timeout}s)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    if [ $elapsed -ge $timeout ]; then
        echo "❌ Timeout waiting for: $description"
        return 1
    else
        echo "✅ Ready: $description"
        return 0
    fi
}

# 1. Check Docker Desktop
echo "1️⃣ Checking Docker Desktop..."
if systemctl --user is-active docker-desktop >/dev/null 2>&1; then
    echo "✅ Docker Desktop is running"
else
    echo "❌ Docker Desktop is not running"
    echo "   Try: systemctl --user start docker-desktop"
    exit 1
fi

# 2. Check Kubernetes
echo "2️⃣ Checking Kubernetes..."
wait_for_condition "kubectl cluster-info >/dev/null 2>&1" "Kubernetes API to be ready"

# 3. Check required namespaces
echo "3️⃣ Checking namespaces..."
for ns in cert-manager actions-runner-system github-runners; do
    if kubectl get namespace "$ns" >/dev/null 2>&1; then
        echo "✅ Namespace $ns exists"
    else
        echo "❌ Namespace $ns missing"
        exit 1
    fi
done

# 4. Check cert-manager
echo "4️⃣ Checking cert-manager..."
wait_for_condition "kubectl get pods -n cert-manager | grep -q 'Running'" "cert-manager pods to be running"

# 5. Check ARC controller
echo "5️⃣ Checking Actions Runner Controller..."
wait_for_condition "kubectl get pods -n actions-runner-system | grep -q 'Running'" "ARC controller to be running"

# 6. Check runner scale set (with minRunners=0, no pods expected at idle)
echo "6️⃣ Checking Runner Scale Set configuration..."
if kubectl get autoscalingrunnersets -n github-runners >/dev/null 2>&1; then
    echo "✅ Runner scale set configured (minRunners=0, will scale on demand)"
else
    echo "❌ Runner scale set not configured"
    exit 1
fi

# 7. Check Helm releases
echo "7️⃣ Checking Helm releases..."
if helm list -n cert-manager | grep -q cert-manager; then
    echo "✅ cert-manager Helm release found"
else
    echo "❌ cert-manager Helm release missing"
    exit 1
fi

if helm list -n actions-runner-system | grep -q arc; then
    echo "✅ ARC Helm release found"
else
    echo "❌ ARC Helm release missing"
    exit 1
fi

if helm list -n github-runners | grep -q arc-runner-set; then
    echo "✅ Runner scale set Helm release found"
else
    echo "❌ Runner scale set Helm release missing"
    exit 1
fi

echo ""
echo "🎉 All checks passed! GitHub Actions Runner setup is ready."
echo "   Runners will automatically scale when GitHub Actions workflows are triggered."
echo "   Organization: 8am-tech"
echo "   Max runners: 5"
echo "   Runner labels: self-hosted, linux, x64, prod"