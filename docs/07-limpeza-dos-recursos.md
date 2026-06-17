# 07 — Limpeza dos recursos

Antes de apagar o Terraform State, destrua os recursos criados pelo laboratório.

## Opção recomendada — Destroy pelo GitHub Actions

Use o workflow:

```text
subscription-vending-destroy
```

Parâmetros:

```text
request_file = requests/app-demo-prd.tfvars.json
destroy_confirm = DESTROY
```

O workflow usa o mesmo backend remoto, a mesma autenticação OIDC e o mesmo request file usado na criação da baseline.

## Opção alternativa — Destroy local

Use apenas se você souber exatamente qual state key foi usada.

```bash
az login --tenant "<SEU_TENANT_ID>" --use-device-code
az account set --subscription "<SUA_SUBSCRIPTION_ID>"

cd terraform
cp ../requests/app-demo-prd.tfvars.json terraform.auto.tfvars.json

terraform init \
  -backend-config="resource_group_name=rg-tfstate-subvending-lab" \
  -backend-config="storage_account_name=<NOME_STORAGE_ACCOUNT_TFSTATE>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=app-demo-prd.tfstate" \
  -backend-config="use_azuread_auth=true"

terraform destroy
```

## Opção manual

Se o Terraform destroy não for possível, remova manualmente:

- Resource Group da workload.
- Budget.
- Role assignments criados.
- Policy assignment opcional.
- NetworkWatcherRG, se foi criado pelo laboratório e não é usado por outro recurso.

## Atenção

Não apague o Storage Account do Terraform State antes de destruir os recursos. Sem o state, você perde a rastreabilidade do que o Terraform criou.
