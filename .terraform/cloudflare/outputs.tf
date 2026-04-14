output "zone_id" {
  description = "Cloudflare Zone ID for base-domain.org"
  value       = data.cloudflare_zone.djtip.id
}

output "dev_wildcard_record" {
  description = "Development wildcard DNS record"
  value = {
    name    = cloudflare_record.dev_wildcard.hostname
    value   = cloudflare_record.dev_wildcard.value
    proxied = cloudflare_record.dev_wildcard.proxied
  }
}

output "staging_wildcard_record" {
  description = "Staging wildcard DNS record"
  value = {
    name    = cloudflare_record.staging_wildcard.hostname
    value   = cloudflare_record.staging_wildcard.value
    proxied = cloudflare_record.staging_wildcard.proxied
  }
}

output "prod_wildcard_record" {
  description = "Production wildcard DNS record"
  value = {
    name    = cloudflare_record.prod_wildcard.hostname
    value   = cloudflare_record.prod_wildcard.value
    proxied = cloudflare_record.prod_wildcard.proxied
  }
}

output "base_domain_ip" {
  description = "Base domain IP address (auto-fetched from DNS)"
  value       = data.cloudflare_record.base_domain.value
}

output "dns_records_summary" {
  description = "Summary of all DNS records created"
  value = <<-EOT
    
    ✅ DNS Records Created:
    
    Development:  *.dev.${var.subdomain}.${var.domain}     → ${var.dev_ip}
    Staging:      *.staging.${var.subdomain}.${var.domain} → ${data.cloudflare_record.base_domain.value} (auto-synced from ${var.base_domain_hostname})
    Production:   *.${var.subdomain}.${var.domain}         → ${data.cloudflare_record.base_domain.value} (auto-synced from ${var.base_domain_hostname})
    
    All records are set to DNS only (not proxied) for cert-manager compatibility.
    
    🔄 Staging/Production IPs are automatically fetched from ${var.base_domain_hostname} DNS record
       When your DDNS updates ${var.base_domain_hostname}, run 'terraform apply' to sync the wildcards
    
    Test your DNS:
      dig app.dev.${var.subdomain}.${var.domain}
      dig app.staging.${var.subdomain}.${var.domain}
      dig app.${var.subdomain}.${var.domain}
    
    Next steps:
      1. Run: ./scripts/setup-cert-manager-wildcard.sh
      2. Monitor: kubectl get certificates -n cert-manager -w
  EOT
}
