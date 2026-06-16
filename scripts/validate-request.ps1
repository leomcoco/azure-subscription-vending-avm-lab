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

if ($request.subscription_id -notmatch "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$") {
  throw "subscription_id deve ser um GUID válido em letras minúsculas."
}

$placeholderValues = @(
  "00000000-0000-0000-0000-000000000000",
  "11111111-1111-1111-1111-111111111111",
  "seu-email@dominio.com"
)

if ($request.subscription_id -in $placeholderValues) {
  throw "subscription_id ainda está com valor de exemplo. Atualize o request file antes de executar."
}

if ($request.contributor_group_object_id -in $placeholderValues) {
  throw "contributor_group_object_id ainda está com valor de exemplo. Atualize o request file antes de executar."
}

if ($request.reader_group_object_id -in $placeholderValues) {
  throw "reader_group_object_id ainda está com valor de exemplo. Atualize o request file antes de executar."
}

foreach ($cidr in @($request.address_space + $request.subnet_workload_prefixes + $request.subnet_private_endpoint_prefixes)) {
  if ($cidr -notmatch "^(?:\d{1,3}\.){3}\d{1,3}/\d{1,2}$") {
    throw "CIDR inválido ou não suportado neste laboratório: $cidr"
  }
}

if ($request.budget_amount -le 0) {
  throw "budget_amount deve ser maior que zero."
}

if ($request.budget_contact_emails.Count -eq 0) {
  throw "budget_contact_emails deve ter pelo menos um e-mail."
}

foreach ($email in $request.budget_contact_emails) {
  if ($email -in $placeholderValues) {
    throw "budget_contact_emails ainda contém e-mail de exemplo. Atualize antes de executar."
  }

  if ($email -notmatch "^[^@\s]+@[^@\s]+\.[^@\s]+$") {
    throw "E-mail inválido em budget_contact_emails: $email"
  }
}

Write-Host "Solicitação validada com sucesso: $($request.request_id)"
Write-Host "Aplicação: $($request.application_name)"
Write-Host "Ambiente: $($request.environment)"
Write-Host "Product line: $($request.product_line)"
