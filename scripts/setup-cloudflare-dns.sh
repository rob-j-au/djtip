#!/bin/bash
set -e

echo "🌐 Setting up Cloudflare DNS with Terraform"
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install terraform
    else
        echo "Please install Terraform: https://www.terraform.io/downloads"
        exit 1
    fi
fi

# Navigate to terraform directory
cd .cicd/terraform/cloudflare

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    
    # Try to auto-populate IPs
    if command -v minikube &> /dev/null; then
        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "192.168.49.2")
        sed -i.bak "s/192.168.49.2/$MINIKUBE_IP/" terraform.tfvars
        echo "✅ Set dev_ip to: $MINIKUBE_IP"
    fi
    
    echo ""
    echo "⚠️  Please edit terraform.tfvars with your values:"
    echo "   - cloudflare_api_token (required)"
    echo "   - staging_ip (your Pi IP)"
    echo "   - prod_ip (your Pi IP)"
    echo ""
    echo "Then run this script again."
    exit 0
fi

# Check if API token is set
if grep -q "your-cloudflare-api-token-here" terraform.tfvars; then
    echo "❌ Please set your Cloudflare API token in terraform.tfvars"
    echo ""
    echo "Get it from: https://dash.cloudflare.com/profile/api-tokens"
    echo "Permissions: Zone → DNS → Edit"
    echo "Zone: djtip.jennings.au"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan
echo ""
echo "📋 Planning changes..."
terraform plan

# Ask for confirmation
echo ""
read -p "Apply these changes? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Aborted"
    exit 0
fi

# Apply
echo ""
echo "🚀 Applying configuration..."
terraform apply -auto-approve

echo ""
echo "✅ Cloudflare DNS setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Wait 1-2 minutes for DNS propagation"
echo "   2. Run: ./scripts/setup-cert-manager-wildcard.sh"
echo "   3. Monitor: kubectl get certificates -n cert-manager -w"
