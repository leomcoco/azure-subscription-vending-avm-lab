output "handoff_summary" {
  description = "Resumo de handoff da landing zone simulada."
  value = {
    request_id        = var.request_id
    subscription_id   = module.lz_vending.subscription_id
    application       = var.application_name
    environment       = var.environment
    product_line      = var.product_line
    resource_group    = local.resource_group_name
    virtual_network   = local.vnet_name
    budget            = var.budget_enabled ? "bud-${local.name_suffix}" : "disabled"
    contributor_role  = var.contributor_group_object_id
    reader_role       = var.reader_group_object_id
    policy_assignment = var.enable_allowed_locations_policy ? azurerm_subscription_policy_assignment.allowed_locations[0].name : "disabled"
    next_step         = "Integrar este workflow ao portal/self-service no Laboratório 2 usando repository_dispatch."
  }
}

output "avm_resource_group_ids" {
  description = "Resource groups criados pelo módulo AVM."
  value       = module.lz_vending.resource_group_resource_ids
}

output "avm_virtual_network_ids" {
  description = "VNets criadas pelo módulo AVM."
  value       = module.lz_vending.virtual_network_resource_ids
}
