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
    
    Development:  *.dev.base-domain.org     → ${var.dev_ip}
    Staging:      *.staging.base-domain.org → ${data.cloudflare_record.base_domain.value} (auto-synced from ${var.domain})
    Production:   *.base-domain.org         → ${data.cloudflare_record.base_domain.value} (auto-synced from ${var.domain})
    
    All records are set to DNS only (not proxied) for cert-manager compatibility.
    
    🔄 Staging/Production IPs are automatically fetched from ${var.domain} DNS record
       When your DDNS updates ${var.domain}, run 'terraform apply' to sync the wildcards
    
    Test your DNS:
      dig djtip.dev.base-domain.org
      dig djtip.staging.base-domain.org
      dig djtip.base-domain.org
    
    Next steps:
      1. Run: ./scripts/setup-cert-manager-wildcard.sh
      2. Monitor: kubectl get certificates -n cert-manager -w
  EOT
}
