# 12 — Publicação segura e evidências

Este checklist deve ser usado antes de tornar o repositório público e antes de publicar o artigo.

## Evidências recomendadas para o artigo

Capture prints de:

1. Estrutura do repositório no GitHub.
2. Request file ou request example.
3. Workflow `subscription-vending-avm` com sucesso.
4. Etapa `Azure login with OIDC`.
5. Etapa `Terraform init`, mostrando download do módulo AVM.
6. Etapa `Terraform plan`, com `0 to destroy`.
7. Etapa `Terraform apply`, com sucesso.
8. `handoff_summary` no output.
9. Resource Group criado.
10. Tags do Resource Group.
11. VNet e subnets.
12. Budget.
13. IAM do Resource Group com os grupos Contributor e Reader.
14. Container `tfstate` no Storage Account.

## Dados que não devem ficar públicos

Antes de abrir o repositório, remova ou sanitize:

- Subscription ID real.
- Tenant ID real.
- Client ID real da App Registration.
- Object IDs dos grupos.
- E-mail pessoal ou corporativo.
- Nome real do Storage Account do Terraform State.
- Arquivos locais de bootstrap.
- Arquivos JSON reais de request.
- Histórico de troubleshooting com IDs reais.

## Comandos recomendados antes de publicar

```bash
git rm --cached requests/app-demo-prd.tfvars.json
git rm --cached -r .git 2>/dev/null || true
git rm --cached setup/bootstrap-output.env 2>/dev/null || true
git rm --cached federated-credential.json 2>/dev/null || true
git rm --cached setup/bootstrap-azure-prereqs.local.sh 2>/dev/null || true

git add .gitignore requests/app-demo-prd.tfvars.example.json
git commit -m "Prepare repository for public release"
git push
```

## Validar se ainda há dados reais

Use buscas simples antes de abrir o repositório:

```bash
grep -R "@" . --exclude-dir=.git
grep -R "de810171" . --exclude-dir=.git
grep -R "b8b91" . --exclude-dir=.git
grep -R "sttf" . --exclude-dir=.git
```

Substitua os termos pelos IDs reais do seu ambiente.

## Recomendação

Mantenha o repositório privado até finalizar:

- Artigo 1.
- Prints.
- Limpeza de dados sensíveis.
- README revisado.
- Arquivo de exemplo validado.
