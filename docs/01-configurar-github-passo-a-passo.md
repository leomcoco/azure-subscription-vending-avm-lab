# 01 — Como configurar o GitHub para este laboratório

Este guia foi escrito para quem ainda não tem familiaridade com GitHub.

## 1. Criar conta no GitHub

1. Acesse https://github.com/
2. Crie uma conta ou entre com sua conta existente.
3. Guarde seu nome de usuário, pois ele será usado no OIDC do Azure.

Exemplo:

```text
GITHUB_OWNER=leonardococo
```

## 2. Criar o repositório

1. No canto superior direito do GitHub, clique no botão `+`.
2. Clique em `New repository`.
3. Em `Repository name`, use:

```text
azure-subscription-vending-avm-lab
```

4. Em `Description`, use algo como:

```text
Laboratório de Subscription Vending no Azure com AVM, Terraform e GitHub Actions.
```

5. Escolha `Public` se quiser usar como contribuição pública para comunidade.
6. Não marque `Add a README file`, pois este pacote já contém um README.
7. Clique em `Create repository`.

Referência oficial: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository

## 3. Fazer upload dos arquivos pelo navegador

Como você ainda não tem familiaridade com Git, a forma mais simples é usar upload pela interface web.

1. Abra o repositório criado.
2. Clique em `Add file`.
3. Clique em `Upload files`.
4. Arraste todos os arquivos e pastas deste pacote para a tela.
5. No campo de commit, use:

```text
Initial subscription vending AVM lab
```

6. Clique em `Commit changes`.

Referência oficial: https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository

## 4. Verificar se o workflow apareceu

1. Acesse a aba `Actions` do repositório.
2. Procure o workflow:

```text
subscription-vending-avm
```

Se ele aparecer, o GitHub reconheceu o arquivo:

```text
.github/workflows/subscription-vending-avm.yml
```

## 5. Criar Repository Variables

Após executar os pré-requisitos no Azure, você precisará criar variáveis no GitHub.

1. Acesse o repositório.
2. Clique em `Settings`.
3. Clique em `Secrets and variables`.
4. Clique em `Actions`.
5. Clique na aba `Variables`.
6. Clique em `New repository variable`.

Crie estas variáveis:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
TF_STATE_RG
TF_STATE_STORAGE_ACCOUNT
TF_STATE_CONTAINER
```

Não crie `AZURE_CLIENT_SECRET`. Este laboratório usa OpenID Connect.

## 6. Rodar o workflow manualmente

1. Acesse `Actions`.
2. Clique em `subscription-vending-avm`.
3. Clique em `Run workflow`.
4. Informe:

```text
request_file = requests/app-demo-prd.tfvars.json
apply = false
```

5. Clique em `Run workflow`.

Se o `plan` funcionar, execute novamente com:

```text
apply = true
```

## 7. Boas práticas para o repositório público

Antes de tornar o repositório público, revise:

- Nenhum segredo foi commitado.
- Nenhum client secret foi salvo.
- Nenhum e-mail pessoal sensível aparece em excesso.
- O subscription ID pode aparecer em laboratório, mas você pode mascarar no artigo se preferir.
- Não coloque dados de ambiente corporativo real.

## 8. Como isso será usado no Artigo 2

O workflow já aceita `repository_dispatch`. No segundo laboratório, o Power Automate vai acionar este mesmo workflow após a aprovação do formulário.

Exemplo conceitual de payload:

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
