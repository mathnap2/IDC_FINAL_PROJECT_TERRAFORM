# Cuentas Claras — Infraestructura (Terraform)

Crea en Azure todo lo que necesitan el backend y el frontend en sus ambientes **dev** y **prod**.

> 📋 **Tablero del proyecto:** [Cuentas Claras](https://github.com/users/angelcortes1705/projects/3)
> · Repos: [backend](https://github.com/mathnap2/IDC_FINAL_PROJECT)
> · [frontend](https://github.com/mathnap2/IDC_FINAL_PROJECT_FRONTEND)
> · [infraestructura](https://github.com/mathnap2/IDC_FINAL_PROJECT_TERRAFORM)

## Recursos

| Recurso | Nombre | Para qué |
|---|---|---|
| Resource Group | `rg-cuentasclaras` | Agrupa todo |
| App Service Plan Linux F1 (gratis) | `asp-cc` | Cómputo compartido; aquí se ven CPU y memoria |
| Web App (contenedor) | `app-cc-api-dev-<sufijo>` | Backend dev, imagen `mathnap2/cuentas-claras:dev` |
| Web App (contenedor) | `app-cc-api-prod-<sufijo>` | Backend prod, imagen `mathnap2/cuentas-claras:latest` |
| Web App (contenedor) | `app-cc-web-dev-<sufijo>` | Frontend dev, imagen `mathnap2/cuentas-claras-front:dev` |
| Web App (contenedor) | `app-cc-web-prod-<sufijo>` | Frontend prod, imagen `mathnap2/cuentas-claras-front:latest` |
| PostgreSQL Flexible Server B1ms | `psql-cc-<sufijo>` | Bases `db_dev` y `db_prod` |

**Regiones:** PostgreSQL vive en `centralus` (`location`) y el App Service en `westus3` (`app_location`). La suscripción de prueba tiene cuota 0 de App Service (B1 y F1) en `centralus` y PostgreSQL B1ms no está disponible en la mayoría de las demás regiones.

**Plan F1:** es gratuito pero no tiene *Always On* (la primera petición tras un rato inactivo tarda) y tiene un límite diario de CPU. Si hay cuota de B1 basta con `plan_sku = "B1"`.

El sufijo aleatorio existe porque los nombres de Web Apps y PostgreSQL son únicos en todo Azure.

## Archivos

| Archivo | Contenido |
|---|---|
| `providers.tf` | Proveedores `azurerm` y `random` |
| `variables.tf` | Suscripción, regiones, SKU del plan, imágenes de Docker Hub y DSN de Sentry |
| `main.tf` | Nombres/URLs calculados, Resource Group y App Service Plan |
| `webapps.tf` | Las 4 Web Apps con sus variables de entorno |
| `database.tf` | PostgreSQL, regla de firewall, bases y cadenas de conexión |
| `identity.tf` | Identidad de GitHub Actions (OIDC) y su permiso sobre el resource group |
| `outputs.tf` | URLs, nombres de Web Apps, valores para GitHub Secrets y cadenas de conexión (sensibles) |

## Variables de entorno que reciben las apps

- **Backend:** `DATABASE_URL`, `SECRET_KEY` (aleatoria por ambiente), `CORS_ORIGINS` (URL del frontend del mismo ambiente), `FLASK_CONFIG=prod`, `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `WEBSITES_PORT=8000`.
- **Frontend:** `API_URL` (URL del backend del mismo ambiente), `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `WEBSITES_PORT=80`.

Las credenciales nunca están en el código: las contraseñas las genera Terraform y solo viven en el estado y en la configuración de la Web App.

## Uso

```bash
az login
cp terraform.tfvars.example terraform.tfvars   # poner subscription_id
terraform init
terraform plan -out=cc.tfplan
terraform apply cc.tfplan
terraform output urls
```

La imagen de cada Web App la actualiza el pipeline de CD; Terraform la ignora (`ignore_changes`) para no regresarla.
El estado (`terraform.tfstate`) es local y no se sube al repo porque contiene contraseñas.

## Despliegue desde GitHub Actions (service connection)

`identity.tf` crea la aplicación `sp-cuentasclaras-github` con **credenciales federadas (OIDC)**: GitHub presenta un
token firmado que dice de qué repo y ambiente viene, y Azure lo acepta sin contraseña. Solo se aceptan workflows de
`IDC_FINAL_PROJECT` e `IDC_FINAL_PROJECT_FRONTEND` que corran en el environment `dev` o `production`, o en un push a
`develop` o `main`. Su permiso es **Website Contributor** sobre `rg-cuentasclaras`: puede cambiar la imagen y
reiniciar las Web Apps, nada más.

### Configuración en cada repo (backend y frontend)

1. **Settings → Secrets and variables → Actions**, con los valores de `terraform output github_secrets`:
   `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (más `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`).
2. **Settings → Environments**: crear `dev` y `production`. En `production` activar
   *Required reviewers*; esa es la aprobación manual antes de producción.

### Ejemplo de job

```yaml
deploy-dev:
  needs: build
  runs-on: ubuntu-latest
  environment: dev            # en prod: environment: production (pide aprobación)
  permissions:
    id-token: write           # necesario para OIDC
    contents: read
  steps:
    - uses: azure/login@v2
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    - uses: azure/webapps-deploy@v3
      with:
        app-name: app-cc-api-dev-4yzr            # ver terraform output webapp_names
        images: docker.io/mathnap2/cuentas-claras:sha-${{ github.sha }}
```
