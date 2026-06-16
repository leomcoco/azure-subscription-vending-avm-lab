# 02 — Preparar Azure, OIDC e backend remoto do Terraform

Este laboratório usa GitHub Actions autenticando no Azure com OpenID Connect.

## Por que usar OIDC?

OIDC evita salvar `client secret` no GitHub. O GitHub Actions solicita um token temporário, e o Microsoft Entra ID confia nesse token por meio de uma federated credential configurada na App Registration.

Referência oficial: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect

## Pré-requisitos

- Azure CLI instalado
- Permissão Owner ou equivalente na subscription do laboratório
- Permissão para criar App Registration no tenant
- GitHub repo criado

## Executar script de bootstrap

Abra o arquivo:

```text
setup/bootstrap-azure-prereqs.sh
```

Atualize as variáveis no início do arquivo:

```bash
SUBSCRIPTION_ID="sua-subscription-id"
GITHUB_OWNER="seu-usuario-github"
GITHUB_REPO="azure-subscription-vending-avm-lab"
```

Depois execute:

```bash
az login
bash setup/bootstrap-azure-prereqs.sh
```

O script cria:

- Resource Group para Terraform state
- Storage Account para Terraform state
- Container `tfstate`
- App Registration
- Service Principal
- Federated credential para GitHub Actions na branch `main`
- Role assignment na subscription
- Role assignment no Storage Account para acessar o state
- Grupos Entra ID de Contributor e Reader

## Importante sobre permissão Owner

Para laboratório, o script usa Owner para reduzir complexidade. Em produção, substitua por menor privilégio conforme seu modelo de plataforma.

## Atualizar o request file

Depois do script, atualize:

```text
requests/app-demo-prd.tfvars.json
```

Campos obrigatórios:

```json
"subscription_id": "sua-subscription-id",
"contributor_group_object_id": "object-id-do-grupo-contributor",
"reader_group_object_id": "object-id-do-grupo-reader",
"budget_contact_emails": ["seu-email@dominio.com"]
```

## Configurar Repository Variables no GitHub

Use os valores exibidos pelo script:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TF_STATE_RG
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

## Primeiro teste recomendado

Execute o workflow com:

```text
apply = false
```

Depois de validar o `plan`, execute novamente com:

```text
apply = true
```
