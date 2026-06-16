variable "request_id" {
  type        = string
  description = "ID rastreável da solicitação de subscription vending."
}

variable "application_name" {
  type        = string
  description = "Nome curto da aplicação ou produto."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,40}$", var.application_name))
    error_message = "application_name deve conter 3 a 40 caracteres usando letras, números e hífen."
  }
}

variable "environment" {
  type        = string
  description = "Ambiente da landing zone. Valores aceitos: dev, hml, prd ou sandbox."

  validation {
    condition     = contains(["dev", "hml", "prd", "sandbox"], var.environment)
    error_message = "environment deve ser dev, hml, prd ou sandbox."
  }
}

variable "product_line" {
  type        = string
  description = "Product line da subscription. Valores aceitos: sandbox, corp-connected ou online."

  validation {
    condition     = contains(["sandbox", "corp-connected", "online"], var.product_line)
    error_message = "product_line deve ser sandbox, corp-connected ou online."
  }
}

variable "subscription_id" {
  type        = string
  description = "ID da subscription existente usada no laboratório. Deve estar em letras minúsculas."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id deve ser um GUID válido em letras minúsculas."
  }
}

variable "management_group_id" {
  type        = string
  description = "ID do management group de destino. Deixe vazio para não mover a subscription no laboratório."
  default     = ""
}

variable "location" {
  type        = string
  description = "Região Azure para os recursos do laboratório."
  default     = "brazilsouth"
}

variable "cost_center" {
  type        = string
  description = "Centro de custo associado à aplicação."
}

variable "technical_owner" {
  type        = string
  description = "Owner técnico responsável pela aplicação."
}

variable "business_owner" {
  type        = string
  description = "Owner de negócio responsável pela aplicação."
}

variable "criticality" {
  type        = string
  description = "Criticidade da workload."

  validation {
    condition     = contains(["low", "medium", "high", "critical"], var.criticality)
    error_message = "criticality deve ser low, medium, high ou critical."
  }
}

variable "data_classification" {
  type        = string
  description = "Classificação dos dados da aplicação."

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification deve ser public, internal, confidential ou restricted."
  }
}

variable "address_space" {
  type        = list(string)
  description = "Address space da VNet."
}

variable "subnet_workload_prefixes" {
  type        = list(string)
  description = "Prefixos da subnet de workload."
}

variable "subnet_private_endpoint_prefixes" {
  type        = list(string)
  description = "Prefixos da subnet de private endpoints."
}

variable "contributor_group_object_id" {
  type        = string
  description = "Object ID do grupo Entra ID que receberá Contributor no resource group da workload."
}

variable "reader_group_object_id" {
  type        = string
  description = "Object ID do grupo Entra ID que receberá Reader no resource group da workload."
}

variable "budget_enabled" {
  type        = bool
  description = "Define se o laboratório cria budget."
  default     = true
}

variable "budget_amount" {
  type        = number
  description = "Valor do budget."
  default     = 500
}

variable "budget_start_date" {
  type        = string
  description = "Data inicial do budget no formato RFC3339. Exemplo: 2026-06-01T00:00:00Z."
}

variable "budget_end_date" {
  type        = string
  description = "Data final do budget no formato RFC3339. Exemplo: 2027-06-01T00:00:00Z."
}

variable "budget_contact_emails" {
  type        = list(string)
  description = "E-mails que receberão alerta de budget."
}


variable "create_network_watcher_rg" {
  type        = bool
  description = "Cria o Resource Group NetworkWatcherRG pelo módulo AVM. Deixe false no primeiro teste para evitar conflito em subscriptions já usadas."
  default     = false
}

variable "enable_allowed_locations_policy" {
  type        = bool
  description = "Habilita uma policy simples de Allowed locations no escopo da subscription. Deixe false no primeiro teste para reduzir risco de falha por permissão."
  default     = false
}

variable "enable_telemetry" {
  type        = bool
  description = "Habilita ou desabilita telemetria do módulo AVM."
  default     = false
}
