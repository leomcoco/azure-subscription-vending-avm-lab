# Subir o laboratório para o GitHub via comandos

Este guia considera que você vai publicar o laboratório com Git e GitHub CLI (`gh`).

## 1. Pré-requisitos locais

Instale ou valide:

```bash
git --version
gh --version
az version
```

Faça login no GitHub CLI:

```bash
gh auth login
```

Escolha GitHub.com, HTTPS e autenticação pelo navegador.

## 2. Entrar na pasta do laboratório

Depois de descompactar o pacote:

```bash
cd azure-subscription-vending-avm-lab
```

## 3. Inicializar o Git local

```bash
git init
git branch -M main
git status
```

## 4. Validar se não existe arquivo sensível

Antes do primeiro commit, confirme que não existem secrets, client secrets, arquivos `.tfstate`, `terraform.auto.tfvars.json` ou plano Terraform versionados.

```bash
git status --short
```

O arquivo `requests/app-demo-prd.tfvars.json` pode ser versionado porque representa a solicitação do laboratório. Antes de tornar o repositório público, revise se o e-mail pode aparecer publicamente.

## 5. Primeiro commit

```bash
git add .
git commit -m "Initial AVM subscription vending lab"
```

## 6. Criar o repositório no GitHub e fazer push

Para criar como público:

```bash
gh repo create azure-subscription-vending-avm-lab \
  --public \
  --source=. \
  --remote=origin \
  --push
```

Para criar como privado primeiro:

```bash
gh repo create azure-subscription-vending-avm-lab \
  --private \
  --source=. \
  --remote=origin \
  --push
```

Recomendação: comece privado enquanto valida o laboratório. Depois, torne público quando remover placeholders e dados que você não quer expor.

## 7. Atualizar arquivos depois

Após alterações:

```bash
git status
git add .
git commit -m "Update lab configuration"
git push
```

## 8. Alternativa sem GitHub CLI

Crie um repositório vazio no GitHub pelo navegador e rode:

```bash
git remote add origin https://github.com/SEU_USUARIO/azure-subscription-vending-avm-lab.git
git push -u origin main
```


## 9. Configurar Repository Variables via comandos

Depois de executar `setup/bootstrap-azure-prereqs.sh`, ele vai imprimir os valores necessários. Dentro da pasta do repositório, use:

```bash
gh variable set AZURE_CLIENT_ID --body "<app-id>"
gh variable set AZURE_TENANT_ID --body "<tenant-id>"
gh variable set AZURE_SUBSCRIPTION_ID --body "<subscription-id>"
gh variable set TF_STATE_RG --body "rg-tfstate-subvending-lab"
gh variable set TF_STATE_STORAGE_ACCOUNT --body "<storage-account-name>"
gh variable set TF_STATE_CONTAINER --body "tfstate"
```

Valide:

```bash
gh variable list
```

## 10. Executar o workflow via comando

Primeiro execute somente o plan:

```bash
gh workflow run subscription-vending-avm.yml \
  -f request_file="requests/app-demo-prd.tfvars.json" \
  -f apply=false
```

Acompanhe:

```bash
gh run list --workflow subscription-vending-avm.yml
gh run watch
```

Depois de validar o plano, execute o apply:

```bash
gh workflow run subscription-vending-avm.yml \
  -f request_file="requests/app-demo-prd.tfvars.json" \
  -f apply=true
```

## 11. Sobre `.terraform.lock.hcl`

Este pacote não inclui `.terraform.lock.hcl` porque o `terraform init` ainda não foi executado no seu ambiente. Depois do primeiro `terraform init` local, avalie versionar o lock file para maior previsibilidade de providers.

Não versione:

- `.tfstate`
- `.tfstate.backup`
- `tfplan`
- `terraform.auto.tfvars.json`
- secrets ou client secrets
