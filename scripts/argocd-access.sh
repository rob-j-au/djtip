#!/bin/bash
# ArgoCD Access Helper Script
# This script helps you quickly access ArgoCD UI and CLI

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ArgoCD Access Helper ===${NC}\n"

# Check if ArgoCD is running
if ! kubectl get namespace argocd &> /dev/null; then
    echo -e "${YELLOW}ArgoCD namespace not found. Please install ArgoCD first.${NC}"
    echo "Run: kubectl create namespace argocd"
    echo "Then: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Get admin password
echo -e "${GREEN}Getting ArgoCD admin password...${NC}"
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

if [ -z "$PASSWORD" ]; then
    echo -e "${YELLOW}Warning: Could not retrieve initial admin password.${NC}"
    echo "You may have already changed it or deleted the secret."
    PASSWORD="<password-not-found>"
fi

echo -e "\n${GREEN}ArgoCD Credentials:${NC}"
echo "  Username: admin"
echo "  Password: $PASSWORD"
echo ""

# Check if port-forward is already running
if pgrep -f "port-forward.*argocd-server" > /dev/null; then
    echo -e "${YELLOW}Port forwarding is already running!${NC}"
    echo -e "Access ArgoCD UI at: ${BLUE}https://localhost:8080${NC}"
    echo ""
    echo "To stop port forwarding, run:"
    echo "  pkill -f 'port-forward.*argocd-server'"
else
    echo -e "${GREEN}Starting port forwarding...${NC}"
    echo -e "Access ArgoCD UI at: ${BLUE}https://localhost:8080${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
    echo ""
    
    # Start port forwarding
    kubectl port-forward svc/argocd-server -n argocd 8080:443
fi
