terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Get the zone ID for the domain
data "cloudflare_zone" "djtip" {
  name = var.domain
}

# Get the current IP from the base domain hostname (e.g., pi.jennings.au)
# This is typically updated by DDNS on your Pi
# The IP from this record is used for staging and production wildcards
data "cloudflare_record" "base_domain" {
  zone_id  = data.cloudflare_zone.djtip.id
  hostname = var.base_domain_hostname
}

# Development wildcard DNS record (*.dev.subdomain.domain)
resource "cloudflare_record" "dev_wildcard" {
  zone_id = data.cloudflare_zone.djtip.id
  name    = "*.dev.${var.subdomain}"
  content = var.dev_ip
  type    = "A"
  ttl     = 1  # Auto
  proxied = false  # MUST be false for cert-manager DNS-01
  comment = "Development environment - Minikube wildcard"
}

# Staging wildcard DNS record (*.staging.subdomain.domain)
# Uses the IP from the base domain hostname (updated via DDNS)
resource "cloudflare_record" "staging_wildcard" {
  zone_id = data.cloudflare_zone.djtip.id
  name    = "*.staging.${var.subdomain}"
  content = data.cloudflare_record.base_domain.value
  type    = "A"
  ttl     = 1  # Auto
  proxied = false  # MUST be false for cert-manager DNS-01
  comment = "Staging environment wildcard (auto-synced from ${var.base_domain_hostname})"
}

# Production wildcard DNS record (*.subdomain.domain)
# Uses the IP from the base domain hostname (updated via DDNS)
resource "cloudflare_record" "prod_wildcard" {
  zone_id = data.cloudflare_zone.djtip.id
  name    = "*.${var.subdomain}"
  content = data.cloudflare_record.base_domain.value
  type    = "A"
  ttl     = 1  # Auto
  proxied = false  # MUST be false for cert-manager DNS-01
  comment = "Production environment wildcard (auto-synced from ${var.base_domain_hostname})"
}

# Optional: Create API token for cert-manager (requires higher permissions)
# Uncomment if you want Terraform to create the API token
# Note: This requires a different API token with User API Tokens Edit permission

# resource "cloudflare_api_token" "cert_manager" {
#   name = "cert-manager-dns01-${var.domain}"
#   
#   policy {
#     permission_groups = [
#       data.cloudflare_api_token_permission_groups.all.permissions["Zone Read"],
#       data.cloudflare_api_token_permission_groups.all.permissions["DNS Write"],
#     ]
#     resources = {
#       "com.cloudflare.api.account.zone.*" = "*"
#     }
#   }
# }
