# Subscription Vending no Azure: automatizando subscriptions governadas com AVM, Terraform e GitHub Actions

**Data de publicação:** [inserir data]  
**Nível técnico:** intermediário/avançado  
**Serviços e ferramentas:** Azure Landing Zones, Azure Verified Modules, Terraform, GitHub Actions, Microsoft Entra ID, OIDC, Azure Policy, Cost Management

## Resumo

Subscription Vending não deve ser tratado apenas como a criação de uma nova subscription. Em ambientes enterprise, o valor está em entregar uma application landing zone com governança mínima desde o primeiro dia: identidade, RBAC, budget, rede, tags, rastreabilidade e handoff operacional.

Neste laboratório, vamos construir um motor de automação usando o módulo oficial **Azure Verified Module para ALZ Subscription Vending**, Terraform e GitHub Actions. Como a criação real de novas subscriptions depende de um modelo de billing compatível, o laboratório usará uma subscription existente para simular a entrega governada.

## O problema

Em muitas empresas, subscriptions são criadas manualmente e depois corrigidas aos poucos. Esse modelo gera inconsistências como:

- ausência de owner técnico e owner de negócio;
- RBAC aplicado diretamente em usuários;
- falta de budget;
- tags inconsistentes;
- rede criada fora do padrão;
- ausência de rastreabilidade da solicitação;
- governança aplicada somente depois da primeira implantação.

Subscription Vending resolve esse problema ao transformar a entrega de subscriptions em um processo padronizado, versionado e automatizado.

## O que é Subscription Vending

A documentação da Microsoft define Subscription Vending como uma automação para padronizar o processo de solicitação, implantação e governança de subscriptions, permitindo que times de aplicação implantem workloads com mais velocidade.

Referência: https://learn.microsoft.com/en-us/azure/architecture/landing-zones/subscription-vending

## Escopo do laboratório

Este artigo implementa o **motor de automação**. O portal self-service será tratado em um segundo artigo.

Fluxo deste laboratório:

```text
Arquivo de solicitação
   ↓
GitHub Actions
   ↓
Validação
   ↓
Terraform plan
   ↓
Terraform apply
   ↓
AVM Subscription Vending Module
   ↓
Subscription existente governada
```

## Por que usar Azure Verified Module

O módulo `Azure/avm-ptn-alz-sub-vending/azure` foi criado para acelerar a implantação de landing zones individuais dentro de um tenant Azure. Ele suporta criação ou uso de subscription existente, associação a management group, resource groups, virtual networks, RBAC, budgets e registro de resource providers.

Referência: https://github.com/Azure/terraform-azure-avm-ptn-alz-sub-vending

Neste laboratório, usaremos o modo com subscription existente:

```hcl
subscription_alias_enabled = false
subscription_id            = var.subscription_id
```

Isso permite que profissionais que não possuem EA, MCA ou MPA também consigam reproduzir a solução.

## Arquitetura da solução

[INSERIR IMAGEM — arquitetura do fluxo]

Componentes principais:

| Componente | Função |
|---|---|
| Request file | Representa a solicitação da landing zone |
| GitHub Actions | Executa validação e Terraform |
| OIDC | Autentica no Azure sem client secret |
| Terraform state remoto | Mantém o estado fora do repositório |
| AVM Subscription Vending | Aplica a baseline governada |
| Handoff output | Resume a entrega para o time consumidor |

## Estrutura do repositório

```text
azure-subscription-vending-avm-lab/
├── requests/
│   └── app-demo-prd.tfvars.json
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── main.tf
│   ├── guardrails.tf
│   ├── outputs.tf
│   └── backend.hcl.example
├── scripts/
│   └── validate-request.ps1
├── .github/
│   └── workflows/
│       └── subscription-vending-avm.yml
└── docs/
```

[INSERIR PRINT — estrutura do repositório]

## Modelo de solicitação

A solicitação fica em um arquivo JSON versionado:

```json
{
  "request_id": "sv-001",
  "application_name": "app-demo",
  "environment": "prd",
  "product_line": "corp-connected",
  "subscription_id": "00000000-0000-0000-0000-000000000000",
  "management_group_id": "",
  "location": "brazilsouth",
  "cost_center": "CC-1001",
  "technical_owner": "squad-cloud-demo",
  "business_owner": "area-negocio-demo",
  "criticality": "medium",
  "data_classification": "internal",
  "address_space": ["10.40.0.0/16"],
  "subnet_workload_prefixes": ["10.40.1.0/24"],
  "subnet_private_endpoint_prefixes": ["10.40.2.0/24"],
  "budget_amount": 500
}
```

Esse modelo é importante porque transforma o vending em uma entrada declarativa, auditável e reutilizável.

## Validação da solicitação

Antes do Terraform, o pipeline executa um script PowerShell que valida campos obrigatórios, ambiente, product line, criticidade, classificação de dados, subscription ID e budget.

[INSERIR PRINT — validação da solicitação no GitHub Actions]

Essa etapa evita que uma solicitação incompleta chegue ao Terraform.

## Autenticação com OIDC

O workflow usa OpenID Connect para autenticação no Azure. Essa abordagem evita armazenar client secret no GitHub.

Referência oficial: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect

No workflow, as permissões incluem:

```yaml
permissions:
  id-token: write
  contents: read
```

E o login no Azure usa:

```yaml
- name: Azure login with OIDC
  uses: azure/login@v2
```

## Terraform com AVM Subscription Vending

O arquivo `main.tf` chama o módulo oficial:

```hcl
module "lz_vending" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = "0.2.1"

  location = var.location

  subscription_alias_enabled = false
  subscription_id            = var.subscription_id

  resource_group_creation_enabled = true
  virtual_network_enabled         = true
  role_assignment_enabled         = true
  budget_enabled                  = var.budget_enabled
}
```

A baseline criada inclui:

- Resource Group da workload;
- NetworkWatcherRG gerenciado pelo Terraform;
- VNet e subnets;
- RBAC para grupos Entra ID;
- Budget;
- Resource provider registration;
- Azure Policy opcional;
- Handoff output.

## GitHub Actions

O workflow aceita dois modos:

| Modo | Uso |
|---|---|
| `workflow_dispatch` | Execução manual no Artigo 1 |
| `repository_dispatch` | Integração com portal no Artigo 2 |

[INSERIR PRINT — workflow manual com apply=false]

Primeiro execute:

```text
apply = false
```

Depois de revisar o plano, execute:

```text
apply = true
```

## Resultado esperado

Após o apply, você deve ver no Azure:

- Resource Group criado;
- VNet criada;
- subnets criadas;
- Budget configurado;
- RBAC aplicado no Resource Group;
- output de handoff no GitHub Actions.

[INSERIR PRINT — recursos criados no Azure]

## Handoff operacional

O output `handoff_summary` entrega um resumo para o time consumidor:

```text
request_id
subscription_id
application
environment
product_line
resource_group
virtual_network
budget
contributor_role
reader_role
```

Esse handoff é importante porque uma plataforma não deve apenas criar recursos. Ela precisa entregar informações operacionais claras para o time que vai consumir a landing zone.

## Como este laboratório prepara o Artigo 2

O workflow já aceita `repository_dispatch`. No próximo artigo, um formulário no Microsoft Forms e um fluxo no Power Automate vão acionar esse mesmo motor após aprovação.

Fluxo do próximo artigo:

```text
Microsoft Forms
   ↓
Power Automate
   ↓
Aprovação
   ↓
GitHub Issue
   ↓
repository_dispatch
   ↓
GitHub Actions
   ↓
Terraform
```

## Limitações do laboratório

Este laboratório não cria uma nova subscription, pois essa capacidade depende de billing e permissões compatíveis, como cenários EA, MCA ou MPA.

A decisão foi usar uma subscription existente para tornar o laboratório replicável para a comunidade técnica.

## Erros comuns

- Usar client secret em vez de OIDC.
- Salvar `.tfstate` no repositório.
- Rodar `apply=true` sem revisar o plan.
- Aplicar Contributor na subscription inteira em laboratório.
- Misturar dados reais corporativos em repositório público.
- Não validar o request file antes do Terraform.
- Criar um portal antes de ter um motor de automação estável.

## Conclusão

Subscription Vending não é apenas criar subscriptions mais rápido. É criar uma experiência padronizada para entregar ambientes governados, rastreáveis e preparados para consumo pelos times de aplicação.

Neste artigo, criamos o motor de automação com AVM, Terraform e GitHub Actions. No próximo artigo, vamos adicionar a camada de self-service com formulário, aprovação e integração com GitHub.

## Referências oficiais

- Subscription Vending implementation guidance: https://learn.microsoft.com/en-us/azure/architecture/landing-zones/subscription-vending
- AVM Subscription Vending Terraform module: https://github.com/Azure/terraform-azure-avm-ptn-alz-sub-vending
- Azure Login com OpenID Connect: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- GitHub Actions documentation: https://docs.github.com/actions
