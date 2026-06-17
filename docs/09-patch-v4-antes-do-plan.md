# Patch v4 — Correções antes do primeiro Terraform Plan

Este patch corrige pontos encontrados na validação do laboratório:

1. Corrige o `repository_dispatch` do GitHub Actions para evitar erro de heredoc no Laboratório 2.
2. Sanitiza o `state_key` usado no backend remoto.
3. Corrige `private_endpoint_network_policies` conforme o schema do AVM.
4. Coloca os namespaces dos resource providers entre aspas no HCL.
5. Torna `NetworkWatcherRG` opcional para evitar conflito em subscriptions já utilizadas.
6. Reforça a validação contra placeholders no request file.
7. Mantém o workflow preparado para `workflow_dispatch` no Artigo 1 e `repository_dispatch` no Artigo 2.

## Arquivos alterados

- `.github/workflows/subscription-vending-avm.yml`
- `terraform/main.tf`
- `terraform/variables.tf`
- `scripts/validate-request.ps1`
- `requests/app-demo-prd.tfvars.json`
- `.gitignore`

## Comandos após substituir os arquivos

```bash
git status
git add .github/workflows/subscription-vending-avm.yml terraform/main.tf terraform/variables.tf scripts/validate-request.ps1 requests/app-demo-prd.tfvars.json .gitignore
git commit -m "Harden AVM workflow and request validation"
git push
```

## Atualizar variáveis do GitHub

Não precisa deletar variáveis antigas. O comando `gh variable set` sobrescreve o valor existente.

```bash
gh variable set AZURE_CLIENT_ID --body "<AZURE_CLIENT_ID_DA_APP_REGISTRATION>"
gh variable set AZURE_TENANT_ID --body "<SEU_TENANT_ID>"
gh variable set AZURE_SUBSCRIPTION_ID --body "<SUA_SUBSCRIPTION_ID>"
gh variable set TF_STATE_RG --body "rg-tfstate-subvending-lab"
gh variable set TF_STATE_STORAGE_ACCOUNT --body "<NOME_STORAGE_ACCOUNT_TFSTATE>"
gh variable set TF_STATE_CONTAINER --body "tfstate"
gh variable list
```

## Atenção ao e-mail de budget

Antes do commit, edite `requests/app-demo-prd.tfvars.json` e substitua:

```json
"substitua-pelo-seu-email@dominio.com"
```

pelo seu e-mail real para receber alertas de budget.
