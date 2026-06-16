#!/usr/bin/env bash
set -euo pipefail

# Preencha antes de executar.
SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
LOCATION="brazilsouth"
STATE_RG="rg-tfstate-subvending-lab"
STATE_STORAGE="sttfsubvending$RANDOM"
STATE_CONTAINER="tfstate"
GITHUB_OWNER="seu-usuario-github"
GITHUB_REPO="azure-subscription-vending-avm-lab"
APP_NAME="app-github-subvending-avm-lab"

if [[ "$SUBSCRIPTION_ID" == "00000000-0000-0000-0000-000000000000" ]]; then
  echo "Atualize SUBSCRIPTION_ID antes de executar."
  exit 1
fi

if [[ "$GITHUB_OWNER" == "seu-usuario-github" ]]; then
  echo "Atualize GITHUB_OWNER antes de executar."
  exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID"

TENANT_ID=$(az account show --query tenantId -o tsv)
SIGNED_IN_USER_ID=$(az ad signed-in-user show --query id -o tsv)

az group create \
  --name "$STATE_RG" \
  --location "$LOCATION" \
  --tags workload="subscription-vending-lab" managedBy="bootstrap-script"

az storage account create \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --tags workload="subscription-vending-lab" managedBy="bootstrap-script"

STATE_STORAGE_ID=$(az storage account show \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query id \
  -o tsv)

# Necessário para criar o container usando Microsoft Entra ID em vez de account key.
az role assignment create \
  --assignee-object-id "$SIGNED_IN_USER_ID" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID" \
  >/dev/null || true

# Aguarda propagação básica do RBAC do Storage. Em alguns tenants pode levar mais tempo.
sleep 30

az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_STORAGE" \
  --auth-mode login

APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
az ad sp create --id "$APP_ID" >/dev/null
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

cat <<JSON > federated-credential.json
{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main",
  "description": "GitHub Actions OIDC for Subscription Vending AVM Lab",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON

az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters federated-credential.json \
  >/dev/null

# Laboratório: Owner simplifica RBAC, budgets, provider registration e policy. Em produção, substitua por menor privilégio.
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Owner" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  >/dev/null

az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID" \
  >/dev/null

CONTRIB_GROUP_ID=$(az ad group create \
  --display-name "grp-az-sv-app-demo-prd-contrib" \
  --mail-nickname "grp-az-sv-app-demo-prd-contrib" \
  --query id \
  -o tsv)

READER_GROUP_ID=$(az ad group create \
  --display-name "grp-az-sv-app-demo-prd-reader" \
  --mail-nickname "grp-az-sv-app-demo-prd-reader" \
  --query id \
  -o tsv)

cat <<OUTPUT

Configuração base concluída.

Crie estas Repository Variables no GitHub:
AZURE_CLIENT_ID=$APP_ID
AZURE_TENANT_ID=$TENANT_ID
AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
TF_STATE_RG=$STATE_RG
TF_STATE_STORAGE_ACCOUNT=$STATE_STORAGE
TF_STATE_CONTAINER=$STATE_CONTAINER

Ou rode estes comandos dentro da pasta do repositório:
gh variable set AZURE_CLIENT_ID --body "$APP_ID"
gh variable set AZURE_TENANT_ID --body "$TENANT_ID"
gh variable set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh variable set TF_STATE_RG --body "$STATE_RG"
gh variable set TF_STATE_STORAGE_ACCOUNT --body "$STATE_STORAGE"
gh variable set TF_STATE_CONTAINER --body "$STATE_CONTAINER"

Atualize o arquivo requests/app-demo-prd.tfvars.json com:
subscription_id=$SUBSCRIPTION_ID
contributor_group_object_id=$CONTRIB_GROUP_ID
reader_group_object_id=$READER_GROUP_ID
budget_contact_emails=[seu e-mail]

Arquivo temporário criado: federated-credential.json
Você pode excluir esse arquivo após validar a configuração.

OUTPUT
