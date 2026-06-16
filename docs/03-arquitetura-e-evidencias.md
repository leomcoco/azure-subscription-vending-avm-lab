# 03 — Arquitetura e evidências para o artigo

## Arquitetura do Laboratório 1

```text
Arquivo de solicitação
   ↓
GitHub Actions
   ↓
Validação da solicitação
   ↓
Terraform plan
   ↓
Terraform apply
   ↓
AVM Subscription Vending Module
   ↓
Subscription existente governada
```

## O que evidenciar no artigo

Capture prints de:

1. Estrutura do repositório no GitHub.
2. Arquivo de solicitação JSON.
3. Workflow `subscription-vending-avm` com execução bem-sucedida.
4. Etapa de validação da solicitação.
5. Terraform plan.
6. Terraform output com `handoff_summary`.
7. Resource Group criado.
8. VNet e subnets criadas.
9. Budget criado.
10. IAM no Resource Group com grupos Entra ID.

## Prints que eu recomendo usar no artigo

Use no máximo 6 a 8 imagens para não cansar o leitor:

- Arquitetura do fluxo.
- Repositório com estrutura.
- Request file.
- GitHub Actions com plan/apply.
- Resource Group/VNet.
- Budget/RBAC.
- Handoff output.

## Checklist final

```text
[ ] Repositório criado
[ ] OIDC configurado
[ ] Terraform state remoto configurado
[ ] Request file validado
[ ] Terraform plan executado
[ ] Terraform apply executado
[ ] Resource Group criado
[ ] VNet criada
[ ] RBAC aplicado em grupos
[ ] Budget criado
[ ] Handoff output gerado
[ ] Workflow preparado para repository_dispatch
```
