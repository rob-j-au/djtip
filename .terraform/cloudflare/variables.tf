variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Base domain name (Cloudflare zone)"
  type        = string
  default     = "base-domain.org"
}

variable "subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"
}

variable "base_domain_hostname" {
  description = "Hostname to fetch IP from (typically updated by DDNS)"
  type        = string
  default     = "pi.base-domain.org"
}

variable "dev_ip" {
  description = "IP address for development environment (Minikube)"
  type        = string
}

# Note: staging_ip and prod_ip are automatically fetched from base_domain_hostname
# This allows the wildcard domains to stay in sync with your DDNS updates
