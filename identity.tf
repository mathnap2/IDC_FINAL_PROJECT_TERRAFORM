# Identidad con la que GitHub Actions despliega en Azure (equivalente a la "service connection" de Azure DevOps).
#
# Usa OIDC (credenciales federadas): GitHub le presenta a Azure un token firmado que dice
# "soy el workflow del repo X en el ambiente Y" y Azure lo acepta sin contraseña.
# Así no existe ningún secreto que se pueda filtrar o que caduque.

data "azurerm_client_config" "actual" {}

resource "azuread_application" "github" {
  display_name = "sp-cuentasclaras-github"
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application.github.client_id
}

locals {
  # Un workflow solo puede desplegar si corre en uno de estos contextos:
  # el environment "dev" o "production" del job, o un push a develop / main.
  sujetos_oidc = merge([
    for nombre, repo in var.github_repos : {
      for ctx in ["environment:dev", "environment:production", "ref:refs/heads/develop", "ref:refs/heads/main"] :
      "${nombre}-${replace(replace(ctx, ":", "-"), "/", "-")}" => "repo:${repo}:${ctx}"
    }
  ]...)
}

resource "azuread_application_federated_identity_credential" "github" {
  for_each = local.sujetos_oidc

  application_id = azuread_application.github.id
  display_name   = substr(each.key, 0, 120)
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value
}

# Permiso mínimo: "Website Contributor" solo sobre el resource group.
# Puede cambiar la imagen y reiniciar las Web Apps, pero no tocar la base de datos ni crear recursos.
resource "azurerm_role_assignment" "github_webapps" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Website Contributor"
  principal_id         = azuread_service_principal.github.object_id
}
