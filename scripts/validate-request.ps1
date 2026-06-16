param(
  [Parameter(Mandatory = $true)]
  [string]$RequestFile
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $RequestFile)) {
  throw "Arquivo de solicitação não encontrado: $RequestFile"
}

try {
  $request = Get-Content $RequestFile -Raw | ConvertFrom-Json
}
catch {
  throw "O arquivo não é um JSON válido: $RequestFile"
}

$requiredFields = @(
  "request_id",
  "application_name",
  "environment",
  "product_line",
  "subscription_id",
  "location",
  "cost_center",
  "technical_owner",
  "business_owner",
  "criticality",
  "data_classification",
  "address_space",
  "subnet_workload_prefixes",
  "subnet_private_endpoint_prefixes",
  "contributor_group_object_id",
  "reader_group_object_id",
  "budget_amount",
  "budget_start_date",
  "budget_end_date",
  "budget_contact_emails"
)

foreach ($field in $requiredFields) {
  if (-not $request.PSObject.Properties.Name.Contains($field)) {
    throw "Campo obrigatório ausente: $field"
  }

  $value = $request.$field
  if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
    throw "Campo obrigatório vazio: $field"
  }
}

$placeholderPatterns = @(
  "^0{8}-0{4}-0{4}-0{4}-0{12}$",
  "^1{8}-1{4}-1{4}-1{4}-1{12}$",
  "^<.*>$",
  "seu-email@dominio.com"
)

foreach ($field in @("subscription_id", "contributor_group_object_id", "reader_group_object_id")) {
  foreach ($pattern in $placeholderPatterns) {
    if ([string]$request.$field -match $pattern) {
      throw "Campo $field ainda contém placeholder: $($request.$field)"
    }
  }
}

$guidRegex = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

foreach ($field in @("subscription_id", "contributor_group_object_id", "reader_group_object_id")) {
  if ([string]$request.$field -notmatch $guidRegex) {
    throw "$field deve ser um GUID válido em letras minúsculas."
  }
}

$allowedEnvironments = @("dev", "hml", "prd", "sandbox")
if ($request.environment -notin $allowedEnvironments) {
  throw "environment inválido: $($request.environment). Use: $($allowedEnvironments -join ', ')."
}

$allowedProductLines = @("sandbox", "corp-connected", "online")
if ($request.product_line -notin $allowedProductLines) {
  throw "product_line inválida: $($request.product_line). Use: $($allowedProductLines -join ', ')."
}

$allowedCriticality = @("low", "medium", "high", "critical")
if ($request.criticality -notin $allowedCriticality) {
  throw "criticality inválida: $($request.criticality)."
}

$allowedDataClassification = @("public", "internal", "confidential", "restricted")
if ($request.data_classification -notin $allowedDataClassification) {
  throw "data_classification inválida: $($request.data_classification)."
}

if ($request.address_space.Count -eq 0) {
  throw "address_space deve ter pelo menos um CIDR."
}

if ($request.subnet_workload_prefixes.Count -eq 0) {
  throw "subnet_workload_prefixes deve ter pelo menos um CIDR."
}

if ($request.subnet_private_endpoint_prefixes.Count -eq 0) {
  throw "subnet_private_endpoint_prefixes deve ter pelo menos um CIDR."
}

if ($request.budget_amount -le 0) {
  throw "budget_amount deve ser maior que zero."
}

try {
  [DateTimeOffset]::Parse($request.budget_start_date) | Out-Null
  [DateTimeOffset]::Parse($request.budget_end_date) | Out-Null
}
catch {
  throw "budget_start_date e budget_end_date devem estar em formato RFC3339. Exemplo: 2026-06-01T00:00:00Z"
}

if ($request.budget_contact_emails.Count -eq 0) {
  throw "budget_contact_emails deve ter pelo menos um e-mail."
}

foreach ($email in $request.budget_contact_emails) {
  foreach ($pattern in $placeholderPatterns) {
    if ([string]$email -match $pattern) {
      throw "budget_contact_emails ainda contém placeholder: $email"
    }
  }

  if ($email -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
    throw "E-mail inválido em budget_contact_emails: $email"
  }
}

Write-Host "Solicitação validada com sucesso: $($request.request_id)"
Write-Host "Aplicação: $($request.application_name)"
Write-Host "Ambiente: $($request.environment)"
Write-Host "Product line: $($request.product_line)"
