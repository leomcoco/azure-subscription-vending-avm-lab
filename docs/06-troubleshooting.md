# 06 — Troubleshooting

## Erro: subscription_id é obrigatório no provider azurerm

O AzureRM Provider 4.x exige `subscription_id` explicitamente no provider ou via variável de ambiente.

Neste laboratório, o provider usa:

```hcl
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

## Erro: OIDC não autentica

Valide:

- `AZURE_CLIENT_ID` está correto no GitHub.
- `AZURE_TENANT_ID` está correto.
- `AZURE_SUBSCRIPTION_ID` está correto.
- A federated credential usa o repo correto.
- A branch é `main`.
- O workflow tem `permissions: id-token: write`.

## Erro: não consegue acessar o Terraform state

Valide se o service principal recebeu:

```text
Storage Blob Data Contributor
```

no Storage Account do Terraform state.

## Erro: não consegue criar role assignment

Valide se a identidade usada pelo GitHub Actions tem permissão suficiente. Para laboratório, foi usado Owner na subscription. Em produção, use menor privilégio.

## Erro: policy assignment falhou

Deixe no primeiro teste:

```json
"enable_allowed_locations_policy": false
```

Depois de validar o fluxo principal, habilite a policy.

## Erro: management group association falhou

Deixe no primeiro teste:

```json
"management_group_id": ""
```

Depois de validar suas permissões, informe o ID do management group.

## Erro: budget falhou

Confirme:

- formato das datas em RFC3339;
- budget_start_date no primeiro dia do mês;
- e-mail válido em budget_contact_emails;
- permissões de Cost Management/Billing suficientes.

Se necessário, use temporariamente:

```json
"budget_enabled": false
```
