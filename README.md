# Azure Subscription Vending AVM Lab

Laboratório didático para demonstrar um motor de automação de **Subscription Vending no Azure** usando:

- Azure Verified Module `Azure/avm-ptn-alz-sub-vending/azure`
- Terraform
- GitHub Actions
- OpenID Connect com Microsoft Entra ID
- Subscription existente, ideal para laboratório com conta MCT ou ambiente pessoal
- `workflow_dispatch` para o Artigo 1
- `repository_dispatch` para integração com portal/self-service no Artigo 2

> Este repositório não cria uma nova subscription por padrão. Ele usa uma subscription existente para simular a entrega de uma application landing zone governada.

## Arquitetura

```text
Request file
   ↓
GitHub Actions
   ↓
Validação da solicitação
   ↓
Terraform init / validate / plan
   ↓
Terraform apply
   ↓
AVM Subscription Vending Module
   ↓
Subscription existente com baseline governada
```

## Baseline aplicada

- Resource Group de workload
- NetworkWatcherRG opcional gerenciado pelo Terraform
- VNet e subnets
- RBAC em grupos Microsoft Entra ID
- Budget
- Resource Provider registration
- Guardrail opcional com Azure Policy
- Output de handoff

## Estrutura

```text
.
├── requests/
├── terraform/
├── scripts/
├── setup/
├── docs/
├── articles/
└── .github/workflows/
```

## Passo rápido

1. Para subir via comandos, leia `docs/00-subir-repositorio-via-comandos.md`.
2. Para subir pela interface web, leia `docs/01-configurar-github-passo-a-passo.md`.
3. Crie ou publique o repositório no GitHub.
4. Execute os pré-requisitos do Azure com `setup/bootstrap-azure-prereqs.sh`.
5. Configure as Repository Variables.
6. Atualize `requests/app-demo-prd.tfvars.json`.
7. Rode o workflow `subscription-vending-avm` com `apply=false`.
8. Depois de validar o plano, rode novamente com `apply=true`.

## Segurança

- Não armazene secrets no repositório.
- Use OIDC em vez de client secret.
- Use `apply=false` primeiro.
- Para laboratório, o RBAC é aplicado no Resource Group, não na subscription inteira.
- Deixe `management_group_id` vazio até validar suas permissões.
- Deixe `enable_allowed_locations_policy=false` no primeiro teste.

## Artigos incluídos

- `articles/artigo-01-subscription-vending-avm-terraform-github-actions.md`
- `articles/artigo-02-portal-self-service-forms-power-automate-github.md`

## Referências oficiais

- Subscription Vending implementation guidance: https://learn.microsoft.com/en-us/azure/architecture/landing-zones/subscription-vending
- AVM Subscription Vending Terraform module: https://github.com/Azure/terraform-azure-avm-ptn-alz-sub-vending
- Azure Login com OIDC no GitHub Actions: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- GitHub connector para Power Automate: https://learn.microsoft.com/en-us/connectors/github/
