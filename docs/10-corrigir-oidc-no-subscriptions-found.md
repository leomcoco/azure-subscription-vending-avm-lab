# Correção: Azure Login com OIDC retornando No subscriptions found

Erro observado no GitHub Actions:

```text
Login failed with Error: The process '/usr/bin/az' failed with exit code 1.
No subscriptions found for ***.
```

## Causa provável

O GitHub Actions conseguiu autenticar no Microsoft Entra ID usando OIDC, mas o Service Principal usado pela App Registration ainda não possui role assignment válido na subscription Azure.

## Correção

Execute:

```bash
chmod +x setup/fix-github-oidc-rbac.sh
./setup/fix-github-oidc-rbac.sh
```

Depois aguarde 2 a 5 minutos para propagação de RBAC e execute novamente:

```bash
gh workflow run subscription-vending-avm.yml \
  -f request_file="requests/app-demo-prd.tfvars.json" \
  -f apply=false
```

## Validação manual

```bash
APP_ID="fa03b26d-bdc3-4bc0-b30e-6ca989f677b1"
SUBSCRIPTION_ID="de810171-07ff-4939-a404-a9a1e5e67487"
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

az role assignment list \
  --assignee "$SP_OBJECT_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query "[].{role:roleDefinitionName, scope:scope, principalType:principalType}" \
  -o table
```

O resultado deve exibir pelo menos `Owner` na subscription para o laboratório.
