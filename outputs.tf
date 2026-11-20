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

output "github_secrets" {
  description = "Valores para los secrets de GitHub (no son contraseñas: con OIDC no hay secreto)"
  value = {
    AZURE_CLIENT_ID       = azuread_application.github.client_id
    AZURE_TENANT_ID       = data.azurerm_client_config.actual.tenant_id
    AZURE_SUBSCRIPTION_ID = data.azurerm_client_config.actual.subscription_id
  }
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.psql.fqdn
}

output "database_urls" {
  description = "terraform output -json database_urls"
  value       = local.database_url
  sensitive   = true
}

output "dashboard_url" {
  description = "Dashboard de métricas en el portal de Azure"
  value       = "https://portal.azure.com/#@${data.azurerm_client_config.actual.tenant_id}/dashboard/arm${azurerm_portal_dashboard.metricas.id}"
}
