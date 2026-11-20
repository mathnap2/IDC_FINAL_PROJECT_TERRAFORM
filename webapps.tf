resource "random_password" "secret_key" {
  for_each = toset(local.ambientes)
  length   = 40
  special  = false
}

# Backend (Flask + Gunicorn en el puerto 8000), uno por ambiente.
resource "azurerm_linux_web_app" "api" {
  for_each = toset(local.ambientes)

  name                = local.nombres[each.key].api
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = merge(local.tags, { ambiente = each.key, componente = "backend" })

  site_config {
    always_on                         = var.plan_sku != "F1"
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 5

    application_stack {
      docker_registry_url = "https://index.docker.io"
      docker_image_name   = "${var.backend_image}:${local.etiqueta[each.key]}"
    }
  }

  app_settings = {
    # Contenedor sin almacenamiento compartido de App Service (lo pone Azure al configurar la imagen).
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "8000"
    FLASK_CONFIG                        = "prod"
    DATABASE_URL                        = local.database_url[each.key]
    SECRET_KEY                          = random_password.secret_key[each.key].result
    CORS_ORIGINS                        = local.urls[each.key].web
    SENTRY_DSN                          = var.sentry_dsn_backend
    SENTRY_ENVIRONMENT                  = each.key
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 3
        retention_in_mb   = 100
      }
    }
  }

  lifecycle {
    # El pipeline de CD cambia la imagen en cada despliegue; Terraform no la regresa.
    ignore_changes = [site_config[0].application_stack[0].docker_image_name]
  }
}

# Frontend (nginx sirviendo HTML/JS en el puerto 80), uno por ambiente.
resource "azurerm_linux_web_app" "web" {
  for_each = toset(local.ambientes)

  name                = local.nombres[each.key].web
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.app_location
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true
  tags                = merge(local.tags, { ambiente = each.key, componente = "frontend" })

  site_config {
    always_on = var.plan_sku != "F1"

    application_stack {
      docker_registry_url = "https://index.docker.io"
      docker_image_name   = "${var.frontend_image}:${local.etiqueta[each.key]}"
    }
  }

  app_settings = {
    # Contenedor sin almacenamiento compartido de App Service (lo pone Azure al configurar la imagen).
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    WEBSITES_PORT                       = "80"
    API_URL                             = local.urls[each.key].api
    SENTRY_DSN                          = var.sentry_dsn_frontend
    SENTRY_ENVIRONMENT                  = each.key
  }

  lifecycle {
    ignore_changes = [site_config[0].application_stack[0].docker_image_name]
  }
}
