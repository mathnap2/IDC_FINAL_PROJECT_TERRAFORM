variable "subscription_id" {
  description = "ID de la suscripción de Azure (az account show --query id -o tsv)"
  type        = string
}

variable "location" {
  description = "Región de Azure. centralus admite PostgreSQL B1ms en la suscripción de prueba."
  type        = string
  default     = "centralus"
}

variable "app_location" {
  description = "Región del App Service Plan y las Web Apps (la suscripción de prueba no tiene cuota de App Service en todas las regiones)"
  type        = string
  default     = "westus3"
}

variable "plan_sku" {
  description = "SKU del App Service Plan. F1 (gratis) porque la suscripción de prueba no tiene cuota de B1."
  type        = string
  default     = "F1"
}

variable "backend_image" {
  description = "Imagen del backend en Docker Hub (sin etiqueta)"
  type        = string
  default     = "mathnap2/cuentas-claras"
}

variable "frontend_image" {
  description = "Imagen del frontend en Docker Hub (sin etiqueta)"
  type        = string
  default     = "mathnap2/cuentas-claras-front"
}

variable "github_repos" {
  description = <<-EOT
    Repos cuyos workflows pueden desplegar en Azure: nombre corto => identificador que GitHub manda en el
    token OIDC. GitHub incluye los IDs numéricos del dueño y del repo (owner@owner_id/repo@repo_id);
    se obtienen con: gh api repos/<owner>/<repo> --jq '"\(.owner.login)@\(.owner.id)/\(.name)@\(.id)"'
  EOT
  type        = map(string)
  default = {
    "idc-final-project"          = "mathnap2@143150021/IDC_FINAL_PROJECT@1456087370"
    "idc-final-project-frontend" = "mathnap2@143150021/IDC_FINAL_PROJECT_FRONTEND@1460719379"
  }
}

variable "db_admin_user" {
  description = "Usuario administrador de PostgreSQL"
  type        = string
  default     = "ccadmin"
}

variable "sentry_dsn_backend" {
  description = "DSN de Sentry del backend (vacío = Sentry desactivado)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sentry_dsn_frontend" {
  description = "DSN de Sentry del frontend (vacío = Sentry desactivado)"
  type        = string
  default     = ""
  sensitive   = true
}
