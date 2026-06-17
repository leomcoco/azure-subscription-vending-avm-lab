# Correção: validação das variáveis TF_STATE no GitHub Actions

## Sintoma

O workflow falha na etapa `Validate GitHub variables` com mensagem semelhante a:

```text
Required variable is empty: TF_STATE_RG
```

## Causa

As variáveis `TF_STATE_RG`, `TF_STATE_STORAGE_ACCOUNT` e `TF_STATE_CONTAINER` existem como Repository Variables no GitHub, mas não estavam mapeadas para o bloco `env` do job.

A etapa de validação lê variáveis de ambiente do runner. Portanto, mesmo com as Repository Variables configuradas no GitHub, elas precisam ser expostas no `env` do workflow.

## Correção

Adicionar ao bloco `jobs.terraform.env` do arquivo `.github/workflows/subscription-vending-avm.yml`:

```yaml
TF_STATE_RG: ${{ vars.TF_STATE_RG }}
TF_STATE_STORAGE_ACCOUNT: ${{ vars.TF_STATE_STORAGE_ACCOUNT }}
TF_STATE_CONTAINER: ${{ vars.TF_STATE_CONTAINER }}
```

## Validação esperada

Após o ajuste, a etapa `Validate GitHub variables` deve exibir:

```text
GitHub variables validated.
```

Depois disso, o workflow deve seguir para Azure Login, Terraform init, Terraform validate e Terraform plan.
