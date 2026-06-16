#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Azure Subscription Vending AVM Lab - Bootstrap v4
# ------------------------------------------------------------------------------
# Diferença da v3:
# - Usa --assignee-object-id e --assignee-principal-type ServicePrincipal para
#   role assignments do GitHub Actions OIDC.
# - Exibe as permissões finais do Service Principal.
# - Mantém compatibilidade com o laboratório atual.
# ============================================================================== 

SUBSCRIPTION_ID="de810171-07ff-4939-a404-a9a1e5e67487"
LOCATION="brazilsouth"
STATE_RG="rg-tfstate-subvending-lab"
STATE_STORAGE="sttfsubvending18167"
STATE_CONTAINER="tfstate"

GITHUB_OWNER="leomcoco"
GITHUB_REPO="azure-subscription-vending-avm-lab"
APP_NAME="app-github-subvending-avm-lab"

CONTRIB_GROUP_NAME="grp-az-sv-app-demo-prd-contrib"
READER_GROUP_NAME="grp-az-sv-app-demo-prd-reader"

fail() { echo "ERRO: $*" >&2; exit 1; }
info() { echo ""; echo "==> $*"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || fail "Comando não encontrado: $1"; }

require_cmd az

[[ -n "$SUBSCRIPTION_ID" && "$SUBSCRIPTION_ID" != "00000000-0000-0000-0000-000000000000" ]] || fail "Atualize SUBSCRIPTION_ID."
[[ -n "$GITHUB_OWNER" && "$GITHUB_OWNER" != "seu-usuario-github" ]] || fail "Atualize GITHUB_OWNER."
[[ -n "$GITHUB_REPO" ]] || fail "Atualize GITHUB_REPO."

info "Validando contexto Azure"
az account set --subscription "$SUBSCRIPTION_ID"
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "Subscription: $SUBSCRIPTION_NAME"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

SIGNED_IN_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
echo "Signed-in user objectId: ${SIGNED_IN_USER_ID:-nao identificado}"

info "Registrando resource providers mínimos"
for provider in Microsoft.Resources Microsoft.Storage Microsoft.Authorization Microsoft.Network Microsoft.CostManagement; do
  az provider register --namespace "$provider" --wait >/dev/null
  echo "Provider registrado/validado: $provider"
done

info "Criando ou validando Resource Group do Terraform State"
az group create --name "$STATE_RG" --location "$LOCATION" --tags workload="subscription-vending-lab" managedBy="bootstrap-script" >/dev/null

info "Criando ou validando Storage Account do Terraform State"
if az storage account show --name "$STATE_STORAGE" --resource-group "$STATE_RG" >/dev/null 2>&1; then
  echo "Storage Account já existe: $STATE_STORAGE"
else
  az storage account create \
    --name "$STATE_STORAGE" \
    --resource-group "$STATE_RG" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --allow-shared-key-access false \
    --tags workload="subscription-vending-lab" managedBy="bootstrap-script" \
    >/dev/null
fi

STATE_STORAGE_ID=$(az storage account show --name "$STATE_STORAGE" --resource-group "$STATE_RG" --query id -o tsv)
echo "Storage Account: $STATE_STORAGE"
echo "Storage Account ID: $STATE_STORAGE_ID"

if [[ -n "$SIGNED_IN_USER_ID" ]]; then
  info "Garantindo acesso do usuário logado ao container via Entra ID"
  az role assignment create \
    --assignee-object-id "$SIGNED_IN_USER_ID" \
    --assignee-principal-type User \
    --role "Storage Blob Data Contributor" \
    --scope "$STATE_STORAGE_ID" \
    >/dev/null 2>&1 || echo "Aviso: role assignment do usuário já existe ou falhou. Continuando."
fi

info "Criando container do Terraform State"
for attempt in 1 2 3 4 5 6; do
  if az storage container create --name "$STATE_CONTAINER" --account-name "$STATE_STORAGE" --auth-mode login --only-show-errors; then
    break
  fi
  echo "Tentativa $attempt falhou. Aguardando propagação de RBAC..."
  sleep 30
done

info "Criando ou reutilizando App Registration"
APP_ID=$(az ad app list --filter "displayName eq '$APP_NAME'" --query "[0].appId" -o tsv 2>/dev/null || true)
if [[ -z "$APP_ID" ]]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --sign-in-audience AzureADMyOrg --query appId -o tsv)
else
  echo "App Registration já existe: $APP_ID"
fi

info "Criando ou validando Service Principal"
az ad sp show --id "$APP_ID" >/dev/null 2>&1 || az ad sp create --id "$APP_ID" >/dev/null
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
echo "App ID: $APP_ID"
echo "Service Principal Object ID: $SP_OBJECT_ID"

info "Configurando Federated Credential OIDC para GitHub Actions"
FEDERATED_CREDENTIAL_NAME="github-main"
EXISTING_FEDERATED_CREDENTIAL=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FEDERATED_CREDENTIAL_NAME'].name | [0]" -o tsv 2>/dev/null || true)
cat <<JSON > federated-credential.json
{
  "name": "$FEDERATED_CREDENTIAL_NAME",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main",
  "description": "GitHub Actions OIDC for Subscription Vending AVM Lab",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
if [[ -z "$EXISTING_FEDERATED_CREDENTIAL" ]]; then
  az ad app federated-credential create --id "$APP_ID" --parameters federated-credential.json >/dev/null
else
  echo "Federated credential já existe: $FEDERATED_CREDENTIAL_NAME"
fi

info "Atribuindo permissões ao Service Principal do GitHub Actions"
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Owner" \
  --scope "$SUBSCRIPTION_SCOPE" \
  -o table || echo "Aviso: Owner já existe ou falhou. Valide manualmente se o workflow falhar."

az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID" \
  -o table || echo "Aviso: Storage Blob Data Contributor já existe ou falhou. Valide manualmente se o terraform init falhar."

info "Criando ou reutilizando grupos Entra ID do laboratório"
CONTRIB_GROUP_ID=$(az ad group list --filter "displayName eq '$CONTRIB_GROUP_NAME'" --query "[0].id" -o tsv 2>/dev/null || true)
if [[ -z "$CONTRIB_GROUP_ID" ]]; then
  CONTRIB_GROUP_ID=$(az ad group create --display-name "$CONTRIB_GROUP_NAME" --mail-nickname "$CONTRIB_GROUP_NAME" --query id -o tsv)
fi
READER_GROUP_ID=$(az ad group list --filter "displayName eq '$READER_GROUP_NAME'" --query "[0].id" -o tsv 2>/dev/null || true)
if [[ -z "$READER_GROUP_ID" ]]; then
  READER_GROUP_ID=$(az ad group create --display-name "$READER_GROUP_NAME" --mail-nickname "$READER_GROUP_NAME" --query id -o tsv)
fi

info "Permissões finais do Service Principal"
az role assignment list --assignee "$SP_OBJECT_ID" --scope "$SUBSCRIPTION_SCOPE" --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" -o table || true
az role assignment list --assignee "$SP_OBJECT_ID" --scope "$STATE_STORAGE_ID" --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" -o table || true

info "Gravando bootstrap-output.env local"
cat <<ENV > setup/bootstrap-output.env
AZURE_CLIENT_ID=$APP_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
TF_STATE_RG=$STATE_RG
TF_STATE_STORAGE_ACCOUNT=$STATE_STORAGE
TF_STATE_CONTAINER=$STATE_CONTAINER
CONTRIBUTOR_GROUP_OBJECT_ID=$CONTRIB_GROUP_ID
READER_GROUP_OBJECT_ID=$READER_GROUP_ID
ENV

cat <<OUTPUT

Configuração base concluída.

Repository Variables no GitHub:
gh variable set AZURE_CLIENT_ID --body "$APP_ID"
gh variable set AZURE_TENANT_ID --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh variable set TF_STATE_RG --body "$STATE_RG"
gh variable set TF_STATE_STORAGE_ACCOUNT --body "$STATE_STORAGE"
gh variable set TF_STATE_CONTAINER --body "$STATE_CONTAINER"

Atualize requests/app-demo-prd.tfvars.json com:
subscription_id=$SUBSCRIPTION_ID
contributor_group_object_id=$CONTRIB_GROUP_ID
reader_group_object_id=$READER_GROUP_ID
budget_contact_emails=[seu e-mail]

Aguarde 2 a 5 minutos antes de executar o GitHub Actions, para propagação do RBAC.

OUTPUT
