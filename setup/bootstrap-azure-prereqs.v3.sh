#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Azure Subscription Vending AVM Lab - Bootstrap v3
# ------------------------------------------------------------------------------
# Objetivo:
# - Criar backend remoto do Terraform em Azure Storage.
# - Criar App Registration + Service Principal para GitHub Actions.
# - Configurar federated credential OIDC para GitHub Actions.
# - Atribuir permissões para o laboratório.
# - Criar grupos Entra ID usados pelo request file.
#
# Importante:
# - Execute com um usuário que tenha Owner na subscription do laboratório.
# - Execute após login explícito no tenant correto:
#   az login --tenant <TENANT_ID> --use-device-code
#   az account set --subscription <SUBSCRIPTION_ID>
# ============================================================================== 

# Preencha antes de executar a cópia LOCAL deste arquivo.
SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
LOCATION="brazilsouth"
STATE_RG="rg-tfstate-subvending-lab"

# Se você já criou a Storage Account em uma execução anterior, reutilize o nome aqui.
# Exemplo do seu ambiente: STATE_STORAGE="sttfsubvending18167"
STATE_STORAGE=""
STATE_CONTAINER="tfstate"

GITHUB_OWNER="leomcoco"
GITHUB_REPO="azure-subscription-vending-avm-lab"
APP_NAME="app-github-subvending-avm-lab"

CONTRIB_GROUP_NAME="grp-az-sv-app-demo-prd-contrib"
READER_GROUP_NAME="grp-az-sv-app-demo-prd-reader"

# ------------------------------------------------------------------------------
# Funções auxiliares
# ------------------------------------------------------------------------------
fail() {
  echo "ERRO: $*" >&2
  exit 1
}

info() {
  echo ""
  echo "==> $*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Comando não encontrado: $1"
}

is_placeholder() {
  [[ "$1" == "00000000-0000-0000-0000-000000000000" || "$1" == "" || "$1" == "seu-usuario-github" ]]
}

require_cmd az

if is_placeholder "$SUBSCRIPTION_ID"; then
  fail "Atualize SUBSCRIPTION_ID antes de executar."
fi

if is_placeholder "$GITHUB_OWNER"; then
  fail "Atualize GITHUB_OWNER antes de executar."
fi

if [[ -z "$STATE_STORAGE" ]]; then
  # Storage Account precisa ser globalmente única e conter apenas letras e números minúsculos.
  STATE_STORAGE="sttfsubvending$RANDOM"
fi

info "Validando contexto Azure"
az account set --subscription "$SUBSCRIPTION_ID"
CURRENT_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

if [[ "$CURRENT_SUBSCRIPTION_ID" != "$SUBSCRIPTION_ID" ]]; then
  fail "Subscription ativa diferente da informada. Ativa=$CURRENT_SUBSCRIPTION_ID Informada=$SUBSCRIPTION_ID"
fi

echo "Subscription: $SUBSCRIPTION_NAME"
echo "Subscription ID: $CURRENT_SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

info "Obtendo Object ID do usuário logado"
SIGNED_IN_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
if [[ -z "$SIGNED_IN_USER_ID" ]]; then
  echo "Aviso: não foi possível obter o Object ID do usuário logado. A criação do container pode depender de permissão já existente no data plane."
else
  echo "Signed-in user objectId: $SIGNED_IN_USER_ID"
fi

info "Registrando resource providers mínimos"
az provider register --namespace Microsoft.Resources --wait >/dev/null
az provider register --namespace Microsoft.Storage --wait >/dev/null
az provider register --namespace Microsoft.Authorization --wait >/dev/null
az provider register --namespace Microsoft.Network --wait >/dev/null
az provider register --namespace Microsoft.CostManagement --wait >/dev/null

info "Criando ou validando Resource Group do Terraform State"
az group create \
  --name "$STATE_RG" \
  --location "$LOCATION" \
  --tags workload="subscription-vending-lab" managedBy="bootstrap-script" \
  >/dev/null

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

STATE_STORAGE_ID=$(az storage account show \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query id \
  -o tsv)

echo "Storage Account: $STATE_STORAGE"
echo "Storage Account ID: $STATE_STORAGE_ID"

if [[ -n "$SIGNED_IN_USER_ID" ]]; then
  info "Atribuindo Storage Blob Data Contributor ao usuário logado para criar o container via Entra ID"
  az role assignment create \
    --assignee "$SIGNED_IN_USER_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STATE_STORAGE_ID" \
    >/dev/null 2>&1 || echo "Aviso: role assignment do usuário no Storage falhou ou já existe. Continuando."
fi

info "Criando container do Terraform State com retry"
CONTAINER_CREATED="false"
for attempt in 1 2 3 4 5 6; do
  if az storage container create \
    --name "$STATE_CONTAINER" \
    --account-name "$STATE_STORAGE" \
    --auth-mode login \
    --only-show-errors >/tmp/subvending-container-create.json 2>/tmp/subvending-container-create.err; then
    cat /tmp/subvending-container-create.json
    CONTAINER_CREATED="true"
    break
  fi

  echo "Tentativa $attempt falhou ao criar container. Aguardando propagação de RBAC..."
  cat /tmp/subvending-container-create.err || true
  sleep 30
done

if [[ "$CONTAINER_CREATED" != "true" ]]; then
  fail "Não foi possível criar o container '$STATE_CONTAINER'. Aguarde alguns minutos e execute novamente."
fi

info "Criando ou reutilizando App Registration"
APP_ID=$(az ad app list --filter "displayName eq '$APP_NAME'" --query "[0].appId" -o tsv 2>/dev/null || true)

if [[ -z "$APP_ID" ]]; then
  if ! APP_ID=$(az ad app create \
    --display-name "$APP_NAME" \
    --sign-in-audience AzureADMyOrg \
    --query appId \
    -o tsv 2>/tmp/subvending-app-create.err); then
    cat /tmp/subvending-app-create.err || true
    fail "Falha ao criar App Registration. Valide se seu usuário pode registrar aplicações no tenant e se o login foi feito no tenant correto: az login --tenant $TENANT_ID --use-device-code"
  fi
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
EXISTING_FEDERATED_CREDENTIAL=$(az ad app federated-credential list \
  --id "$APP_ID" \
  --query "[?name=='$FEDERATED_CREDENTIAL_NAME'].name | [0]" \
  -o tsv 2>/dev/null || true)

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
  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters federated-credential.json \
    >/dev/null
else
  echo "Federated credential já existe: $FEDERATED_CREDENTIAL_NAME"
fi

info "Atribuindo permissões para o laboratório"
# Laboratório: Owner simplifica RBAC, budgets, provider registration e policy. Em produção, substitua por menor privilégio.
az role assignment create \
  --assignee "$APP_ID" \
  --role "Owner" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  >/dev/null 2>&1 || echo "Aviso: Owner na subscription já existe ou falhou. Valide permissões se o workflow falhar."

az role assignment create \
  --assignee "$APP_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID" \
  >/dev/null 2>&1 || echo "Aviso: Storage Blob Data Contributor já existe ou falhou. Valide permissões se o terraform init falhar."

info "Criando ou reutilizando grupos Entra ID do laboratório"
CONTRIB_GROUP_ID=$(az ad group list --filter "displayName eq '$CONTRIB_GROUP_NAME'" --query "[0].id" -o tsv 2>/dev/null || true)
if [[ -z "$CONTRIB_GROUP_ID" ]]; then
  CONTRIB_GROUP_ID=$(az ad group create \
    --display-name "$CONTRIB_GROUP_NAME" \
    --mail-nickname "$CONTRIB_GROUP_NAME" \
    --query id \
    -o tsv)
fi

READER_GROUP_ID=$(az ad group list --filter "displayName eq '$READER_GROUP_NAME'" --query "[0].id" -o tsv 2>/dev/null || true)
if [[ -z "$READER_GROUP_ID" ]]; then
  READER_GROUP_ID=$(az ad group create \
    --display-name "$READER_GROUP_NAME" \
    --mail-nickname "$READER_GROUP_NAME" \
    --query id \
    -o tsv)
fi

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

Arquivo local gerado:
setup/bootstrap-output.env

Arquivo temporário criado:
federated-credential.json

Antes de tornar o repositório público, confirme que arquivos locais e IDs reais não serão publicados.

OUTPUT
