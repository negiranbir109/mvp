output "id" {
  description = "Key Vault identifier."
  value       = azurerm_key_vault.kv.id
}

output "name" {
  description = "Key Vault name."
  value       = azurerm_key_vault.kv.name
}

output "uri" {
  description = "Key Vault URI for performing operations on keys and secrets."
  value       = azurerm_key_vault.kv.vault_uri
}

output "private_endpoint" {
  description = "Key Vault private endpoint."
  value       = var.enable_private_endpoint ? element(concat(azurerm_private_endpoint.keyvault_private_endpoint.*.id, [""]), 0) : null
}

output "private_dns_zone_domain" {
  description = "Key Vault private endpoint DNS record."
  value       = var.enable_private_endpoint ? element(concat(azurerm_private_dns_zone.keyvault_private_dns_zone.*.name, [""]), 0) : null
}

output "private_endpoint_ip_addresses" {
  description = "Key Vault private endpoint IP addresses."
  value       = var.enable_private_endpoint ? flatten(azurerm_private_endpoint.keyvault_private_endpoint.0.custom_dns_configs.*.ip_addresses) : null
}

output "private_endpoint_fqdn" {
  description = "Key Vault private endpoint fully-qualified domain name (FQDN) address."
  value       = var.enable_private_endpoint ? flatten(azurerm_private_endpoint.keyvault_private_endpoint.0.custom_dns_configs.*.fqdn) : null
}