# Ajuste final do GitHub Actions Summary

Este ajuste melhora a seção **GitHub Step Summary** do workflow `subscription-vending-avm.yml`.

## Objetivo

Evitar que os campos de resumo apareçam vazios na tela de evidência do GitHub Actions.

O resumo passa a exibir em tabela:

- request file usado;
- chave do Terraform state;
- se o apply foi solicitado;
- resumo do Terraform plan.

## Resultado esperado para validação de idempotência

Após uma execução com `apply=false`, depois de o ambiente já ter sido criado, o resumo deve apresentar:

```text
No changes. Your infrastructure matches the configuration.
```

ou:

```text
Plan: 0 to add, 0 to change, 0 to destroy.
```

Esse print é uma boa evidência para o artigo porque demonstra que a automação é idempotente.

## Observação

Também foi adicionada a variável:

```yaml
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

para reduzir o aviso de depreciação das actions baseadas em Node.js 20, conforme mensagem exibida pelo próprio GitHub Actions.
