#!/bin/bash
# Setup local TLS certificates for Minikube development

set -e

echo "🔐 Setting up local TLS certificates for Minikube..."

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo "❌ mkcert not found. Please install it first:"
    echo "   macOS:  brew install mkcert"
    echo "   Linux:  See https://github.com/FiloSottile/mkcert#installation"
    exit 1
fi

# Install local CA
echo "📜 Installing local CA..."
mkcert -install

# Create certs directory
mkdir -p certs

# Generate wildcard certificate
echo "🔑 Generating wildcard certificate for *.minikube.local..."
mkcert -cert-file certs/minikube-local.crt \
       -key-file certs/minikube-local.key \
       "*.minikube.local" \
       "minikube.local"

# Create secrets in all namespaces
echo "🔒 Creating Kubernetes secrets..."

# Development
kubectl create secret tls djtip-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -

# Staging
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls djtip-staging-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n staging \
  --dry-run=client -o yaml | kubectl apply -f -

# Production
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls djtip-production-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n production \
  --dry-run=client -o yaml | kubectl apply -f -

# Observability
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls grafana-tls \
  --cert=certs/minikube-local.crt \
  --key=certs/minikube-local.key \
  -n observability \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Local TLS setup complete!"
echo ""
echo "📋 Certificate details:"
openssl x509 -in certs/minikube-local.crt -noout -subject -dates
echo ""
echo "🔍 Verify secrets:"
echo "   kubectl get secrets -A | grep tls"
echo ""
echo "🌐 Access your applications:"
echo "   https://djtip.minikube.local"
echo "   https://djtip-staging.minikube.local"
echo "   https://grafana.minikube.local"
