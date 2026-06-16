# Correção: Terraform init com 403 AuthorizationPermissionMismatch no Azure Storage

Erro observado:

```text
Error: Failed to get existing workspaces: containers.Client#ListBlobs: Failure responding to request: StatusCode=403 Code="AuthorizationPermissionMismatch"
```

## Causa

O GitHub Actions já autenticou no Azure via OIDC, mas o backend remoto do Terraform precisa acessar o **data plane** do Azure Blob Storage para listar, criar e atualizar o state.

A role `Owner` no Storage Account é uma permissão de management plane. Para autenticação via Microsoft Entra ID no backend `azurerm`, o principal também precisa de permissão de data plane, como `Storage Blob Data Contributor`, preferencialmente no container `tfstate` ou no Storage Account.

## Correção pelo Azure Portal

1. Acesse o Storage Account `sttfsubvending18167`.
2. Acesse **Access Control (IAM)**.
3. Clique em **Add role assignment**.
4. Selecione a role **Storage Blob Data Contributor**.
5. Em Members, selecione o service principal `app-github-subvending-avm-lab`.
6. Confirme em **Review + assign**.
7. Aguarde de 5 a 10 minutos para propagação.

## Correção alternativa via Azure CLI

Se a sua sessão Azure CLI conseguir executar role assignments:

```bash
APP_ID="fa03b26d-bdc3-4bc0-b30e-6ca989f677b1"
STATE_RG="rg-tfstate-subvending-lab"
STATE_STORAGE="sttfsubvending18167"

SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
STATE_STORAGE_ID=$(az storage account show \
  --name "$STATE_STORAGE" \
  --resource-group "$STATE_RG" \
  --query id \
  -o tsv)

az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$STATE_STORAGE_ID"
```

## Validação

Depois da propagação, execute novamente:

```bash
gh workflow run subscription-vending-avm.yml \
  -f request_file="requests/app-demo-prd.tfvars.json" \
  -f apply=false
```

O workflow deve avançar de `Terraform init` para `Terraform fmt`, `Terraform validate` e `Terraform plan`.
