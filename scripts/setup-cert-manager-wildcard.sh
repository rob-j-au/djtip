#!/bin/bash
set -e

echo "🔐 Setting up cert-manager with Cloudflare DNS-01 wildcards"

# Check for Cloudflare API token
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "❌ Please set CLOUDFLARE_API_TOKEN environment variable"
  echo ""
  echo "Get it from: https://dash.cloudflare.com/profile/api-tokens"
  echo "Permissions needed: Zone → DNS → Edit"
  echo ""
  echo "Then run:"
  echo "  export CLOUDFLARE_API_TOKEN='your-token-here'"
  echo "  $0"
  exit 1
fi

# Create Cloudflare secret
echo "🔑 Creating Cloudflare API token secret..."
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  -n cert-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Install Reflector
echo "🔄 Installing Reflector..."
helm repo add emberstack https://emberstack.github.io/helm-charts 2>/dev/null || true
helm repo update
helm upgrade --install reflector emberstack/reflector -n cert-manager

# Apply ClusterIssuer
echo "🌐 Creating Cloudflare ClusterIssuer..."
kubectl apply -f .cicd/helm/cert-manager/templates/clusterissuer-cloudflare.yaml

# Apply wildcard certificates
echo "📜 Creating wildcard certificates..."
kubectl apply -f .cicd/helm/cert-manager/templates/certificate-wildcards.yaml

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Certificates will be issued in 1-2 minutes"
echo ""
echo "🔍 Monitor progress:"
echo "  kubectl get certificates -n cert-manager -w"
echo ""
echo "🌐 Your domains:"
echo "  Development:  https://djtip.dev.djtip.jennings.au"
echo "  Staging:      https://djtip.staging.djtip.jennings.au"
echo "  Production:   https://djtip.djtip.jennings.au"
echo ""
echo "  Grafana Dev:  https://grafana.dev.djtip.jennings.au"
echo "  Grafana Stg:  https://grafana.staging.djtip.jennings.au"
echo "  Grafana Prod: https://grafana.djtip.jennings.au"
