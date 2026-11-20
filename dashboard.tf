# Dashboard del portal de Azure con las métricas que se muestran en la presentación:
# CPU y memoria del App Service Plan, y requests, errores y tiempo de respuesta de las Web Apps.

locals {
  # aggregationType del portal: 1 = Suma, 3 = Máximo, 4 = Promedio
  graficas = [
    {
      titulo = "CPU del App Service Plan (asp-cc)"
      metricas = [{
        id         = azurerm_service_plan.plan.id, ns = "microsoft.web/serverfarms", nombre = "CpuPercentage",
        agregacion = 4, etiqueta = "CPU %"
      }]
    },
    {
      titulo = "Memoria del App Service Plan (asp-cc)"
      metricas = [{
        id         = azurerm_service_plan.plan.id, ns = "microsoft.web/serverfarms", nombre = "MemoryPercentage",
        agregacion = 4, etiqueta = "Memoria %"
      }]
    },
    {
      titulo = "Requests por Web App"
      metricas = concat(
        [for amb in local.ambientes : {
          id         = azurerm_linux_web_app.api[amb].id, ns = "microsoft.web/sites", nombre = "Requests",
          agregacion = 1, etiqueta = "API ${amb}"
        }],
        [for amb in local.ambientes : {
          id         = azurerm_linux_web_app.web[amb].id, ns = "microsoft.web/sites", nombre = "Requests",
          agregacion = 1, etiqueta = "Web ${amb}"
        }]
      )
    },
    {
      titulo = "Respuestas 4xx y 5xx del backend"
      metricas = flatten([for amb in local.ambientes : [
        {
          id         = azurerm_linux_web_app.api[amb].id, ns = "microsoft.web/sites", nombre = "Http4xx",
          agregacion = 1, etiqueta = "4xx ${amb}"
        },
        {
          id         = azurerm_linux_web_app.api[amb].id, ns = "microsoft.web/sites", nombre = "Http5xx",
          agregacion = 1, etiqueta = "5xx ${amb}"
        },
      ]])
    },
    {
      titulo = "Tiempo de respuesta del backend"
      metricas = [for amb in local.ambientes : {
        id         = azurerm_linux_web_app.api[amb].id, ns = "microsoft.web/sites", nombre = "HttpResponseTime",
        agregacion = 4, etiqueta = "API ${amb}"
      }]
    },
    {
      titulo = "Memoria usada por Web App"
      metricas = concat(
        [for amb in local.ambientes : {
          id         = azurerm_linux_web_app.api[amb].id, ns = "microsoft.web/sites", nombre = "AverageMemoryWorkingSet",
          agregacion = 4, etiqueta = "API ${amb}"
        }],
        [for amb in local.ambientes : {
          id         = azurerm_linux_web_app.web[amb].id, ns = "microsoft.web/sites", nombre = "AverageMemoryWorkingSet",
          agregacion = 4, etiqueta = "Web ${amb}"
        }]
      )
    },
  ]

  # Dos gráficas por renglón, cada una de 6 x 4 celdas.
  partes_dashboard = {
    for i, g in local.graficas : tostring(i) => {
      position = { x = (i % 2) * 6, y = floor(i / 2) * 4, colSpan = 6, rowSpan = 4 }
      metadata = {
        type = "Extension/HubsExtension/PartType/MonitorChartPart"
        inputs = [
          {
            name = "options"
            value = {
              chart = {
                title     = g.titulo
                titleKind = 1
                metrics = [for m in g.metricas : {
                  resourceMetadata    = { id = m.id }
                  name                = m.nombre
                  aggregationType     = m.agregacion
                  namespace           = m.ns
                  metricVisualization = { displayName = m.etiqueta }
                }]
                visualization = { chartType = 2 }
                timespan      = { relative = { duration = 86400000 } } # últimas 24 h
              }
            }
          },
          { name = "sharedTimeRange", isOptional = true },
        ]
        settings = {}
      }
    }
  }
}

resource "azurerm_portal_dashboard" "metricas" {
  name                = "dash-cuentasclaras"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = merge(local.tags, { "hidden-title" = "Cuentas Claras - Métricas" })

  dashboard_properties = jsonencode({
    lenses = {
      "0" = { order = 0, parts = local.partes_dashboard }
    }
    metadata = {
      model = {
        timeRange = {
          value = { relative = { duration = 24, timeUnit = 1 } }
          type  = "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })
}
