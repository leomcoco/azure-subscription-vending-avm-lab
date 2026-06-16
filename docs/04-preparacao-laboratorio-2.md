# 04 — Preparação para o Laboratório 2

O Laboratório 2 vai adicionar um portal/self-service ao motor de automação do Laboratório 1.

## Fluxo futuro

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
   ↓
Handoff
```

## Por que o workflow já aceita repository_dispatch?

Para evitar refatoração no segundo artigo. O mesmo motor de automação pode ser chamado manualmente no Artigo 1 ou por um portal/formulário no Artigo 2.

## Operações úteis do GitHub Connector

No Power Automate, o conector GitHub permite criar issue e disparar `repository_dispatch`.

Referência oficial: https://learn.microsoft.com/en-us/connectors/github/

## Payload recomendado para o Artigo 2

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

## Melhorias futuras

- Criar Pull Request em vez de acionar apply direto.
- Criar approval environment no GitHub para produção.
- Atualizar a GitHub Issue com status do pipeline.
- Gravar handoff em comentário da issue.
- Integrar com ServiceNow ou Azure DevOps Boards.
