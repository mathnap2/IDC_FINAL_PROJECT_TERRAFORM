output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "urls" {
  description = "URLs públicas de cada ambiente"
  value       = local.urls
}

output "webapp_names" {
  description = "Nombres de las Web Apps (los usa el pipeline de CD)"
  value       = local.nombres
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.psql.fqdn
}

output "database_urls" {
  description = "terraform output -json database_urls"
  value       = local.database_url
  sensitive   = true
}
