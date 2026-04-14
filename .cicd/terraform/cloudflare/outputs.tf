output "zone_id" {
  description = "Cloudflare Zone ID for djtip.jennings.au"
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

output "pi_ip_address" {
  description = "Pi IP address (auto-fetched from pi.jennings.au)"
  value       = data.cloudflare_record.pi.value
}

output "dns_records_summary" {
  description = "Summary of all DNS records created"
  value = <<-EOT
    
    ✅ DNS Records Created:
    
    Development:  *.dev.djtip.jennings.au     → ${var.dev_ip}
    Staging:      *.staging.djtip.jennings.au → ${data.cloudflare_record.pi.value} (auto-synced from pi.jennings.au)
    Production:   *.djtip.jennings.au         → ${data.cloudflare_record.pi.value} (auto-synced from pi.jennings.au)
    
    All records are set to DNS only (not proxied) for cert-manager compatibility.
    
    🔄 Pi IP is automatically fetched from pi.jennings.au DNS record
       When your Cloudflare DDNS updates pi.jennings.au, run 'terraform apply' to sync the wildcards
    
    Test your DNS:
      dig djtip.dev.djtip.jennings.au
      dig djtip.staging.djtip.jennings.au
      dig djtip.djtip.jennings.au
    
    Next steps:
      1. Run: ./scripts/setup-cert-manager-wildcard.sh
      2. Monitor: kubectl get certificates -n cert-manager -w
  EOT
}
