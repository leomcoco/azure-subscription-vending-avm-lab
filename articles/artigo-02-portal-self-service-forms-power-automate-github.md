# Subscription Vending no Azure: criando um portal self-service com Forms, Power Automate e GitHub Actions

**Data de publicação:** [inserir data]  
**Nível técnico:** intermediário  
**Serviços e ferramentas:** Microsoft Forms, Power Automate, GitHub, GitHub Actions, Terraform, Azure Landing Zones

## Resumo

No artigo anterior, criamos o motor de automação de Subscription Vending usando AVM, Terraform e GitHub Actions. Neste segundo artigo, vamos adicionar a camada de entrada self-service, permitindo que um solicitante envie uma demanda por formulário, passe por aprovação e acione o mesmo pipeline de automação.

## Objetivo

Criar uma experiência simples de portal usando:

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
Terraform com AVM
```

## Por que não criar um portal customizado agora

Um portal customizado pode ser interessante, mas aumenta a complexidade. Para um laboratório replicável, Microsoft Forms e Power Automate entregam a experiência de entrada, aprovação e integração sem desviar o foco do tema principal: Subscription Vending.

## Pré-requisito

Antes deste artigo, o leitor deve ter implementado o laboratório anterior:

- repositório GitHub;
- workflow `subscription-vending-avm`;
- OIDC configurado;
- Terraform state remoto;
- request file validado;
- execução manual do pipeline funcionando.

## Formulário de solicitação

Campos recomendados no Microsoft Forms:

| Campo | Tipo | Obrigatório |
|---|---|---|
| Nome da aplicação | Texto | Sim |
| Ambiente | Escolha | Sim |
| Product line | Escolha | Sim |
| Região Azure | Escolha | Sim |
| Owner técnico | Texto | Sim |
| Owner de negócio | Texto | Sim |
| Centro de custo | Texto | Sim |
| Criticidade | Escolha | Sim |
| Classificação de dados | Escolha | Sim |
| Budget mensal | Número | Sim |
| Justificativa | Texto longo | Sim |

## Fluxo Power Automate

Etapas sugeridas:

1. Gatilho: nova resposta enviada no Microsoft Forms.
2. Obter detalhes da resposta.
3. Criar aprovação.
4. Se aprovado, criar GitHub Issue.
5. Montar payload JSON.
6. Criar repository_dispatch no GitHub.
7. Atualizar a issue com o status inicial.

Referência GitHub Connector: https://learn.microsoft.com/en-us/connectors/github/

## Issue de rastreabilidade

A issue pode conter:

```text
Request ID: sv-portal-001
Application: app-portal-demo
Environment: prd
Product line: corp-connected
Cost center: CC-1001
Technical owner: squad-cloud-demo
Business owner: area-negocio-demo
Status: Approved
```

## Payload para repository_dispatch

```json
{
  "event_type": "subscription-vending-request",
  "client_payload": {
    "apply": "false",
    "request": {
      "request_id": "sv-portal-001",
      "application_name": "app-portal-demo",
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
      "address_space": ["10.41.0.0/16"],
      "subnet_workload_prefixes": ["10.41.1.0/24"],
      "subnet_private_endpoint_prefixes": ["10.41.2.0/24"],
      "contributor_group_object_id": "00000000-0000-0000-0000-000000000000",
      "reader_group_object_id": "11111111-1111-1111-1111-111111111111",
      "budget_enabled": true,
      "budget_amount": 500,
      "budget_start_date": "2026-06-01T00:00:00Z",
      "budget_end_date": "2027-06-01T00:00:00Z",
      "budget_contact_emails": ["seu-email@dominio.com"],
      "enable_allowed_locations_policy": false,
      "enable_telemetry": false
    }
  }
}
```

## Estratégia de segurança

Para laboratório:

- iniciar sempre com `apply=false`;
- revisar o Terraform plan;
- executar `apply=true` somente após validação;
- evitar dados reais de produção;
- não salvar secrets em issue ou request file;
- usar OIDC no GitHub Actions.

Para ambiente enterprise:

- usar Pull Request obrigatório;
- exigir revisão do time de plataforma;
- usar GitHub Environments com aprovação;
- criar política de branch protection;
- integrar com ITSM corporativo;
- gerar handoff automático para o solicitante.

## Evidências para o artigo

Capturar prints de:

1. Formulário criado.
2. Fluxo Power Automate.
3. Aprovação.
4. GitHub Issue criada.
5. repository_dispatch executado.
6. GitHub Actions acionado automaticamente.
7. Terraform plan.
8. Comentário de handoff ou resumo final.

## Conclusão

O portal self-service é a porta de entrada da plataforma, mas o valor está na integração com um motor de automação confiável, versionado e auditável.

Com Forms, Power Automate e GitHub Actions, é possível demonstrar uma experiência end-to-end de Subscription Vending sem criar um portal customizado do zero.

## Referências oficiais

- Subscription Vending implementation guidance: https://learn.microsoft.com/en-us/azure/architecture/landing-zones/subscription-vending
- GitHub Connector para Power Automate: https://learn.microsoft.com/en-us/connectors/github/
- GitHub Actions documentation: https://docs.github.com/actions
- Azure Login com OpenID Connect: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
