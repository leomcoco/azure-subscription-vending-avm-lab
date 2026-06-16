# Guardrail opcional para demonstrar governança como código.
# Mantenha enable_allowed_locations_policy = false no primeiro teste.
# Depois de validar permissões e impacto, habilite no request file.

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  count = var.enable_allowed_locations_policy ? 1 : 0

  name                 = "sv-allowed-locations"
  display_name         = "SV - Allowed locations"
  subscription_id      = var.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = [var.location]
    }
  })
}
