# 07 — Limpeza dos recursos

Antes de apagar o Terraform state, destrua os recursos criados pelo laboratório.

## Opção 1 — Destroy local

No seu terminal:

```bash
az login
az account set --subscription "sua-subscription-id"
cd terraform

cp ../requests/app-demo-prd.tfvars.json terraform.auto.tfvars.json

terraform init \
  -backend-config="resource_group_name=rg-tfstate-subvending-lab" \
  -backend-config="storage_account_name=sttfsubvending00000" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=app-demo-prd.tfstate" \
  -backend-config="use_oidc=false"

terraform destroy
```

## Opção 2 — Apagar manualmente depois do laboratório

Se o Terraform destroy não for possível, remova manualmente os recursos criados:

- Resource Group da workload.
- Budget.
- Role assignments criados.
- Policy assignment opcional.
- NetworkWatcherRG criado pelo laboratório, se não for usado por outro recurso.

## Atenção

Não apague o Storage Account do Terraform state antes de destruir os recursos, senão você perde o estado do laboratório.
