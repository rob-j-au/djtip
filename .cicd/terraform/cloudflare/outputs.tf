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

output "dns_records_summary" {
  description = "Summary of all DNS records created"
  value = <<-EOT
    
    ✅ DNS Records Created:
    
    Development:  *.dev.djtip.jennings.au     → ${var.dev_ip}
    Staging:      *.staging.djtip.jennings.au → ${var.staging_ip}
    Production:   *.djtip.jennings.au         → ${var.prod_ip}
    
    All records are set to DNS only (not proxied) for cert-manager compatibility.
    
    Test your DNS:
      dig djtip.dev.djtip.jennings.au
      dig djtip.staging.djtip.jennings.au
      dig djtip.djtip.jennings.au
    
    Next steps:
      1. Run: ./scripts/setup-cert-manager-wildcard.sh
      2. Monitor: kubectl get certificates -n cert-manager -w
  EOT
}
