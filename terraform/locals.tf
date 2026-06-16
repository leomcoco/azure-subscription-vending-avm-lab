locals {
  location_short = var.location == "brazilsouth" ? "brs" : lower(replace(var.location, " ", ""))

  app_name_normalized = lower(replace(var.application_name, "_", "-"))
  name_suffix         = "${local.app_name_normalized}-${var.environment}-${local.location_short}"

  enable_management_group_association = trim(var.management_group_id) != ""

  resource_group_name = "rg-${local.name_suffix}-001"
  vnet_name           = "vnet-${local.name_suffix}-001"

  common_tags = {
    application        = var.application_name
    environment        = var.environment
    productLine        = var.product_line
    costCenter         = var.cost_center
    technicalOwner     = var.technical_owner
    businessOwner      = var.business_owner
    criticality        = var.criticality
    dataClassification = var.data_classification
    managedBy          = "subscription-vending-avm-lab"
    requestId          = var.request_id
  }

  workload_resource_group = {
    workload = {
      name     = local.resource_group_name
      location = var.location
      tags     = local.common_tags
    }
  }

  network_watcher_resource_group = var.create_network_watcher_rg ? {
    network_watcher = {
      name     = "NetworkWatcherRG"
      location = var.location
      tags     = local.common_tags
    }
  } : {}

  resource_groups = merge(local.workload_resource_group, local.network_watcher_resource_group)
}
