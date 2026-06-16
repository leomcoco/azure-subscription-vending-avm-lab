locals {
  avm_resource_groups = merge(
    {
      workload = {
        name     = local.resource_group_name
        location = var.location
        tags     = local.common_tags
      }
    },
    var.create_network_watcher_rg ? {
      network_watcher = {
        name     = "NetworkWatcherRG"
        location = var.location
        tags     = local.common_tags
      }
    } : {}
  )
}

module "lz_vending" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "0.2.1"

  location = var.location

  # Lab mode: use an existing subscription instead of creating a new one.
  subscription_alias_enabled = false
  subscription_id            = var.subscription_id

  # Optional: enable only if your account can associate subscriptions to management groups.
  subscription_management_group_association_enabled = local.enable_management_group_association
  subscription_management_group_id                  = local.enable_management_group_association ? var.management_group_id : null

  resource_group_creation_enabled = true
  resource_groups                 = local.avm_resource_groups

  virtual_network_enabled = true
  virtual_networks = {
    spoke = {
      name               = local.vnet_name
      resource_group_key = "workload"
      address_space      = var.address_space
      tags               = local.common_tags

      subnets = {
        workload = {
          name                            = "snet-workload-001"
          address_prefixes                = var.subnet_workload_prefixes
          default_outbound_access_enabled = false
        }

        private_endpoints = {
          name                              = "snet-privateendpoints-001"
          address_prefixes                  = var.subnet_private_endpoint_prefixes
          private_endpoint_network_policies = "Disabled"
          default_outbound_access_enabled   = false
        }
      }
    }
  }

  role_assignment_enabled = true
  role_assignments = {
    app_contributor_rg = {
      principal_id             = var.contributor_group_object_id
      definition               = "Contributor"
      resource_group_scope_key = "workload"
      principal_type           = "Group"
    }

    app_reader_rg = {
      principal_id             = var.reader_group_object_id
      definition               = "Reader"
      resource_group_scope_key = "workload"
      principal_type           = "Group"
    }
  }

  budget_enabled = var.budget_enabled
  budgets = var.budget_enabled ? {
    subscription_budget = {
      name              = "bud-${local.name_suffix}"
      amount            = var.budget_amount
      time_grain        = "Monthly"
      time_period_start = var.budget_start_date
      time_period_end   = var.budget_end_date

      notifications = {
        eighty_percent = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 80
          threshold_type = "Actual"
          contact_emails = var.budget_contact_emails
          locale         = "pt-br"
        }

        hundred_percent = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 100
          threshold_type = "Actual"
          contact_emails = var.budget_contact_emails
          locale         = "pt-br"
        }
      }
    }
  } : {}

  subscription_register_resource_providers_enabled = true
  subscription_register_resource_providers_and_features = {
    "Microsoft.Authorization"  = []
    "Microsoft.CostManagement" = []
    "Microsoft.Network"        = []
    "Microsoft.Resources"      = []
  }

  enable_telemetry = var.enable_telemetry
}
