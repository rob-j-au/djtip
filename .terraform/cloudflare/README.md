# Terraform Cloudflare DNS Configuration

Automates the creation of wildcard DNS records in Cloudflare for cert-manager.

## What This Does

Creates 3 wildcard DNS A records:
- `*.dev.djtip.jennings.au` → Your Minikube IP (manual)
- `*.staging.djtip.jennings.au` → **Auto-fetched from base domain**
- `*.djtip.jennings.au` → **Auto-fetched from base domain**

All records are set to **DNS only** (not proxied) for cert-manager DNS-01 challenges.

### 🔄 Automatic IP Sync

The staging and production wildcards automatically use the IP from your base domain (configured in the `domain` variable), which is kept up-to-date by your DDNS service. When your IP changes:

1. DDNS updates your base domain's A record
2. Run `terraform apply` to sync the wildcards
3. Done! No manual IP entry needed

## Prerequisites

1. **Cloudflare account** with `djtip.jennings.au` domain
2. **Cloudflare API token** with DNS edit permissions
3. **Terraform** installed (`brew install terraform`)

## Quick Start

### 1. Install Terraform

```bash
brew install terraform
```

### 2. Get Your IPs

```bash
# Minikube IP
minikube ip

# Pi IP
ssh pi "hostname -I | awk '{print \$1}'"
```

### 3. Create terraform.tfvars

```bash
cd .terraform/cloudflare

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**terraform.tfvars:**
```hcl
cloudflare_api_token = "your-actual-cloudflare-api-token-here"
domain               = "djtip.jennings.au"
dev_ip              = "192.168.49.2"      # Your Minikube IP

# Note: staging and production IPs are auto-fetched from pi.jennings.au
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Preview Changes

```bash
terraform plan
```

### 6. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Outputs

After applying, you'll see:

```
Outputs:

base_domain_ip = "203.0.113.42"  # Auto-fetched from base domain

dns_records_summary = <<EOT

✅ DNS Records Created:

Development:  *.dev.djtip.jennings.au     → 192.168.49.2
Staging:      *.staging.djtip.jennings.au → 203.0.113.42 (auto-synced from djtip.jennings.au)
Production:   *.djtip.jennings.au         → 203.0.113.42 (auto-synced from djtip.jennings.au)

All records are set to DNS only (not proxied) for cert-manager compatibility.

🔄 Staging/Production IPs are automatically fetched from djtip.jennings.au DNS record
   When your DDNS updates djtip.jennings.au, run 'terraform apply' to sync the wildcards

Test your DNS:
  dig djtip.dev.djtip.jennings.au
  dig djtip.staging.djtip.jennings.au
  dig djtip.djtip.jennings.au

Next steps:
  1. Run: ./scripts/setup-cert-manager-wildcard.sh
  2. Monitor: kubectl get certificates -n cert-manager -w
EOT
```

## Verify DNS Records

```bash
# Test development
dig djtip.dev.djtip.jennings.au

# Test staging
dig djtip.staging.djtip.jennings.au

# Test production
dig djtip.djtip.jennings.au
```

## Update IPs

If your IPs change (e.g., Minikube restart):

```bash
# Update terraform.tfvars with new IPs
nano terraform.tfvars

# Apply changes
terraform apply
```

## Destroy Resources

To remove all DNS records:

```bash
terraform destroy
```

## Files

```
.terraform/cloudflare/
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars.example     # Example variables file
├── terraform.tfvars             # Your actual variables (gitignored)
└── README.md                    # This file
```

## Security

- `terraform.tfvars` is gitignored (contains API token)
- Never commit your API token to git
- Use `.tfvars.example` as a template

## Cloudflare API Token

### Create Token:

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **Create Token**
3. Use **Edit zone DNS** template
4. Permissions: `Zone → DNS → Edit`
5. Zone Resources: `Include → Specific zone → djtip.jennings.au`
6. Create and copy token

### Token Permissions Required:

```
Zone → DNS → Edit
Zone: djtip.jennings.au
```

## Troubleshooting

### Error: Invalid API token

- Check token is correct in `terraform.tfvars`
- Verify token has DNS edit permissions
- Check token hasn't expired

### Error: Zone not found

- Verify domain name is correct
- Check token has access to the zone

### DNS not resolving

- Wait 1-5 minutes for DNS propagation
- Check records in Cloudflare dashboard
- Verify proxy status is OFF (grey cloud)

## Integration with cert-manager

After Terraform creates the DNS records:

```bash
# 1. Set up cert-manager with the same API token
export CLOUDFLARE_API_TOKEN="your-token-here"
./scripts/setup-cert-manager-wildcard.sh

# 2. Monitor certificate issuance
kubectl get certificates -n cert-manager -w
```

## Terraform State

Terraform state is stored locally in `terraform.tfstate`.

**For team environments**, consider using remote state:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "cloudflare/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Additional Resources

- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
- [cert-manager Setup](../../../docs/CERT_MANAGER.md)
