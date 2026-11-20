# Sufijo aleatorio: los nombres de Web Apps y PostgreSQL deben ser únicos en todo Azure.
resource "random_string" "sufijo" {
  length  = 4
  upper   = false
  special = false
}

locals {
  sufijo    = random_string.sufijo.result
  ambientes = ["dev", "prod"]

  # Nombres y URLs se calculan aquí para que backend y frontend se conozcan
  # (CORS y URL de la API) sin crear dependencias circulares.
  nombres = {
    for amb in local.ambientes : amb => {
      api = "app-cc-api-${amb}-${local.sufijo}"
      web = "app-cc-web-${amb}-${local.sufijo}"
    }
  }
  urls = {
    for amb in local.ambientes : amb => {
      api = "https://${local.nombres[amb].api}.azurewebsites.net"
      web = "https://${local.nombres[amb].web}.azurewebsites.net"
    }
  }

  # Etiqueta de Docker Hub por ambiente: develop -> :dev, main -> :latest
  etiqueta = { dev = "dev", prod = "latest" }

  tags = { proyecto = "cuentas-claras" }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cuentasclaras"
  location = var.location
  tags     = local.tags
}

# Un solo plan Linux comparte el cómputo de las 4 Web Apps.
# Sus métricas de CPU y memoria son las que se muestran en el portal.
resource "azurerm_service_plan" "plan" {
  name                = "asp-cc"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  os_type             = "Linux"
  sku_name            = var.plan_sku
  tags                = local.tags
}
