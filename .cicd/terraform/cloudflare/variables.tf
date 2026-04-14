variable "cloudflare_api_token" {
  description = "Cloudflare API token with DNS edit permissions"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Base domain name"
  type        = string
  default     = "djtip.jennings.au"
}

variable "dev_ip" {
  description = "IP address for development environment (Minikube)"
  type        = string
}

# Note: staging_ip and prod_ip are automatically fetched from pi.jennings.au DNS record
# This allows the wildcard domains to stay in sync with your Cloudflare DDNS updates
