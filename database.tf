resource "random_password" "db" {
  length  = 24
  special = false # sin caracteres especiales para que la URL de conexión no necesite escaparse
}

# Un solo servidor (B1ms, incluido en los servicios gratis de 12 meses) con una base por ambiente.
resource "azurerm_postgresql_flexible_server" "psql" {
  name                          = "psql-cc-${local.sufijo}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  backup_retention_days         = 7
  administrator_login           = var.db_admin_user
  administrator_password        = random_password.db.result
  public_network_access_enabled = true
  tags                          = local.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

# 0.0.0.0 - 0.0.0.0 es la regla especial de Azure que permite conexiones desde servicios de Azure
# (las Web Apps), no desde internet.
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure" {
  name             = "permitir-servicios-azure"
  server_id        = azurerm_postgresql_flexible_server.psql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  for_each  = toset(local.ambientes)
  name      = "db_${each.key}"
  server_id = azurerm_postgresql_flexible_server.psql.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

locals {
  database_url = {
    for amb in local.ambientes : amb =>
    "postgresql://${var.db_admin_user}:${random_password.db.result}@${azurerm_postgresql_flexible_server.psql.fqdn}:5432/db_${amb}?sslmode=require"
  }
}
