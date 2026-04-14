#!/bin/bash
# Deploy djtip stack to Pi Kubernetes cluster

set -e

echo "🚀 Deploying djtip stack to Pi Kubernetes..."

# Check if we can connect to Pi
if ! ssh pi "kubectl get nodes" > /dev/null 2>&1; then
    echo "❌ Cannot connect to Pi Kubernetes cluster"
    exit 1
fi

echo "✅ Connected to Pi Kubernetes cluster"

# Install ArgoCD if not already installed
if ! ssh pi "kubectl get namespace argocd" > /dev/null 2>&1; then
    echo "📦 Installing ArgoCD..."
    ssh pi "kubectl create namespace argocd"
    ssh pi "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    
    echo "⏳ Waiting for ArgoCD to be ready..."
    ssh pi "kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd"
    
    echo "✅ ArgoCD installed"
else
    echo "✅ ArgoCD already installed"
fi

# Apply ArgoCD applications
echo "📝 Applying ArgoCD applications..."

# Copy manifests to Pi
scp .cicd/argocd/pi/*.yaml pi:/tmp/

# Apply each application
ssh pi "kubectl apply -f /tmp/haproxy-ingress.yaml"
echo "✅ HAProxy Ingress application created"

ssh pi "kubectl apply -f /tmp/observability.yaml"
echo "✅ Observability application created"

ssh pi "kubectl apply -f /tmp/djtip-staging.yaml"
echo "✅ Staging application created"

ssh pi "kubectl apply -f /tmp/djtip-production.yaml"
echo "✅ Production application created"

# Clean up
ssh pi "rm /tmp/*.yaml"

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "📊 Check application status:"
echo "  ssh pi 'kubectl get applications -n argocd'"
echo ""
echo "🌐 Access URLs (configure DNS to point to Pi):"
echo "  Staging:     https://djtip-staging.k8s.pi.jennings.au"
echo "  Production:  https://djtip.k8s.pi.jennings.au"
echo "  Grafana:     https://grafana.k8s.pi.jennings.au"
echo ""
echo "🔑 Get ArgoCD admin password:"
echo "  ssh pi 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d'"
echo ""
