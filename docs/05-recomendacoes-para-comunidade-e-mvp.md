# 05 — Recomendações para comunidade técnica e evidência MVP

Este laboratório foi estruturado para ser útil para a comunidade Azure e também funcionar como evidência pública de contribuição técnica.

## O que fortalece o conteúdo

- Usar referência oficial da Microsoft e módulo AVM oficial.
- Mostrar limitação real do laboratório sem esconder o cenário.
- Explicar por que usamos subscription existente.
- Evitar tutorial manual de portal.
- Entregar repositório reutilizável.
- Incluir README, documentação e artigos.
- Usar GitHub Actions com OIDC, sem client secret.
- Separar motor de automação e portal self-service em dois artigos.
- Incluir prints de execução real.
- Incluir erros comuns e decisões de arquitetura.

## Como publicar no GitHub

Sugestão de descrição do repositório:

```text
Laboratório de Subscription Vending no Azure usando Azure Verified Modules, Terraform, GitHub Actions e OIDC, preparado para integração com portal self-service.
```

Tópicos sugeridos:

```text
azure
terraform
azure-landing-zones
subscription-vending
github-actions
azure-verified-modules
cloud-governance
platform-engineering
finops
```

## Como publicar no blog

Artigo 1:

```text
Subscription Vending no Azure: automatizando subscriptions governadas com AVM, Terraform e GitHub Actions
```

Artigo 2:

```text
Subscription Vending no Azure: criando um portal self-service com Forms, Power Automate e GitHub Actions
```

## Cuidados antes de publicar

- Remover IDs reais que você não queira expor.
- Mascarar subscription ID nos prints, se preferir.
- Não expor e-mails pessoais desnecessários.
- Não usar dados de ambiente corporativo real.
- Não publicar secrets, tokens ou client secrets.
- Deixar claro que a criação real de subscriptions depende de billing/permissões enterprise.

## Checklist de evidência pública

```text
[ ] Repositório público no GitHub
[ ] README claro
[ ] Artigo publicado no blog
[ ] Prints do laboratório
[ ] Referências oficiais
[ ] Link para o GitHub no artigo
[ ] Post no LinkedIn divulgando o conteúdo
[ ] Comentários respondidos com ajuda técnica
[ ] Código reutilizável para comunidade
```
