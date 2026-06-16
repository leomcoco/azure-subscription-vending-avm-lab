#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Corrige/valida permissões do Service Principal usado pelo GitHub Actions OIDC.
# Uso:
#   1) Edite as variáveis abaixo.
#   2) Execute: chmod +x setup/fix-github-oidc-rbac.sh
#   3) Execute: ./setup/fix-github-oidc-rbac.sh
# ============================================================================== 

SUBSCRIPTION_ID="de810171-07ff-4939-a404-a9a1e5e67487"
TENANT_ID="b8b91fa5-7eac-448d-b404-2f0a0d94bcd0"
APP_ID="fa03b26d-bdc3-4bc0-b30e-6ca989f677b1"
STATE_RG="rg-tfstate-subvending-lab"
STATE_STORAGE="sttfsubvending18167"

fail() {
  echo "ERRO: $*" >&2
  exit 1
}

info() {
  echo ""
  echo "==> $*"
}

command -v az >/dev/null 2>&1 || fail "Azure CLI não encontrado."

info "Validando login e subscription"
az account set --subscription "$SUBSCRIPTION_ID"
az account show --query "{name:name, subscriptionId:id, tenantId:tenantId}" -o table

CURRENT_TENANT_ID=$(az account show --query tenantId -o tsv)
if [[ "$CURRENT_TENANT_ID" != "$TENANT_ID" ]]; then
  fail "Tenant ativo diferente do esperado. Execute: az login --tenant $TENANT_ID --use-device-code"
fi

info "Obtendo Service Principal"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv 2>/dev/null || true)
if [[ -z "$SP_OBJECT_ID" ]]; then
  fail "Service Principal não encontrado para APP_ID=$APP_ID. Reexecute o bootstrap."
fi

echo "App ID: $APP_ID"
echo "Service Principal Object ID: $SP_OBJECT_ID"

SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"

info "Permissões atuais do Service Principal na subscription"
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "$SUBSCRIPTION_SCOPE" \
  --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" \
  -o table || true

info "Atribuindo Owner na subscription usando assignee-object-id"
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Owner" \
  --scope "$SUBSCRIPTION_SCOPE" \
  -o table || echo "Aviso: Owner já existe ou falhou. Veja a mensagem acima."

info "Obtendo Storage Account ID"
STATE_STORAGE_ID=$(az storage account show \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query id \
  -o tsv)

echo "Storage Account ID: $STATE_STORAGE_ID"

info "Atribuindo Storage Blob Data Contributor no Terraform State"
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID" \
  -o table || echo "Aviso: Storage Blob Data Contributor já existe ou falhou. Veja a mensagem acima."

info "Permissões finais do Service Principal na subscription"
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "$SUBSCRIPTION_SCOPE" \
  --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" \
  -o table

info "Permissões finais do Service Principal no Storage Account"
az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "$STATE_STORAGE_ID" \
  --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" \
  -o table

cat <<OUTPUT

Correção concluída.
Aguarde 2 a 5 minutos para propagação do RBAC no Azure e execute novamente o workflow com apply=false.

Comando sugerido:
gh workflow run subscription-vending-avm.yml \
  -f request_file="requests/app-demo-prd.tfvars.json" \
  -f apply=false

OUTPUT
