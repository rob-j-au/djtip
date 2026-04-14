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

variable "staging_ip" {
  description = "IP address for staging environment (Pi cluster)"
  type        = string
}

variable "prod_ip" {
  description = "IP address for production environment (Pi cluster)"
  type        = string
}
