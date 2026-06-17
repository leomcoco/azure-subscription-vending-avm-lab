# Azure Subscription Vending AVM Lab

Laboratório didático para demonstrar um motor de automação de **Subscription Vending no Azure** usando:

- Azure Verified Module `Azure/avm-ptn-alz-sub-vending/azure`
- Terraform
- GitHub Actions
- OpenID Connect com Microsoft Entra ID
- Terraform State remoto em Azure Storage
- Subscription existente, ideal para laboratório com conta MCT ou ambiente pessoal
- `workflow_dispatch` para o Laboratório 1
- `repository_dispatch` para integração com portal/self-service no Laboratório 2

> Este repositório não cria uma nova subscription por padrão. Ele usa uma subscription existente para simular a entrega de uma application landing zone governada.

## Status do laboratório

O fluxo foi validado em modo laboratório com:

- `terraform plan` executado com sucesso.
- `terraform apply` executado com sucesso.
- OIDC funcionando sem client secret.
- Backend remoto funcionando com Azure Storage.
- Baseline criada por Terraform usando o módulo AVM.

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

- Resource Group de workload.
- VNet e subnets.
- RBAC em grupos Microsoft Entra ID no escopo do Resource Group.
- Budget.
- Resource Provider registration.
- NetworkWatcherRG opcional.
- Guardrail opcional com Azure Policy.
- Output de handoff.

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
6. Crie seu request file a partir de `requests/app-demo-prd.tfvars.example.json`.
7. Rode o workflow `subscription-vending-avm` com `apply=false`.
8. Depois de validar o plano, rode novamente com `apply=true`.

## Segurança antes de tornar público

Antes de abrir o repositório para a comunidade, leia:

- `docs/12-publicacao-segura-e-evidencias.md`

A recomendação é manter no repositório público apenas o arquivo:

```text
requests/app-demo-prd.tfvars.example.json
```

E remover do controle de versão qualquer arquivo real como:

```text
requests/app-demo-prd.tfvars.json
setup/bootstrap-output.env
setup/*.local.sh
federated-credential.json
```

## Laboratório 2

O workflow principal já está preparado para receber um evento `repository_dispatch`. Isso permite integrar um portal/self-service no segundo artigo usando:

```text
Microsoft Forms ou Power Apps
↓
Power Automate
↓
Aprovação
↓
GitHub repository_dispatch
↓
GitHub Actions
↓
Terraform
```

Contrato técnico do Laboratório 2:

- `docs/13-contrato-laboratorio-2-repository-dispatch.md`

## Limpeza

Para remover os recursos criados pelo laboratório, use o workflow:

```text
subscription-vending-destroy
```

Ele exige confirmação explícita com:

```text
DESTROY
```

## Artigos incluídos

- `articles/artigo-01-subscription-vending-avm-terraform-github-actions.md`
- `articles/artigo-02-portal-self-service-forms-power-automate-github.md`

## Referências oficiais

- Subscription Vending implementation guidance: https://learn.microsoft.com/en-us/azure/architecture/landing-zones/subscription-vending
- AVM Subscription Vending Terraform module: https://github.com/Azure/terraform-azure-avm-ptn-alz-sub-vending
- Azure Login com OIDC no GitHub Actions: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- GitHub connector para Power Automate: https://learn.microsoft.com/en-us/connectors/github/
