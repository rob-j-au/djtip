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

variable "vultr_vps_ip" {
  description = "Vultr VPS IP address (forwards to Pi via Tailscale)"
  type        = string
}

# Note: staging_ip and prod_ip use vultr_vps_ip which forwards to Pi via Tailscale
# The VPS has iptables rules to forward ports 80/443 to Pi's Tailscale IP
