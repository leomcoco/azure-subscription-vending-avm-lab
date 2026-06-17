# 13 — Contrato para o Laboratório 2: repository_dispatch

O Laboratório 2 vai adicionar uma entrada self-service usando Microsoft Forms, Power Automate ou outro portal.

O objetivo é acionar o mesmo workflow do Laboratório 1 sem alterar o Terraform.

## Fluxo esperado

```text
Formulário / Portal
↓
Power Automate
↓
Aprovação
↓
GitHub repository_dispatch
↓
Workflow subscription-vending-avm
↓
Terraform plan/apply
```

## Evento esperado

O workflow recebe:

```json
{
  "event_type": "subscription-vending-request",
  "client_payload": {
    "apply": false,
    "request": {
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
      "address_space": [
        "10.40.0.0/16"
      ],
      "subnet_workload_prefixes": [
        "10.40.1.0/24"
      ],
      "subnet_private_endpoint_prefixes": [
        "10.40.2.0/24"
      ],
      "contributor_group_object_id": "00000000-0000-0000-0000-000000000000",
      "reader_group_object_id": "11111111-1111-1111-1111-111111111111",
      "create_network_watcher_rg": false,
      "budget_enabled": true,
      "budget_amount": 500,
      "budget_start_date": "2026-06-01T00:00:00Z",
      "budget_end_date": "2027-06-01T00:00:00Z",
      "budget_contact_emails": [
        "seu-email@dominio.com"
      ],
      "enable_allowed_locations_policy": false,
      "enable_telemetry": false
    }
  }
}
```

## Regras importantes

- `apply=false` deve ser o padrão inicial.
- O approval deve acontecer antes de `apply=true`.
- O request deve passar pelo mesmo `validate-request.ps1`.
- O request não precisa ser commitado no repositório quando vier por `repository_dispatch`.
- O `request_id` define a chave do Terraform State.
- O Power Automate deve registrar a issue ou o protocolo da solicitação.

## Como isso ajuda o Artigo 2

O segundo artigo pode focar na experiência self-service:

- Formulário.
- Aprovação.
- Criação de issue.
- Chamada do `repository_dispatch`.
- Acompanhamento do status.
- Handoff para o solicitante.

O motor técnico permanece o mesmo do Laboratório 1.
