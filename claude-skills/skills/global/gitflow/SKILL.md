---
name: gitflow
description: Use SEMPRE que uma tarefa em qualquer projeto do Alessandro for começar, ramificar, nomear branch, commitar, abrir correção urgente ou fechar trabalho — "vamos fazer X", "corrige Y", "cria a branch", "faz o commit", "hotfix", "qual branch eu uso". Define o Gitflow padrão: de onde sair, como nomear, onde mesclar e quando apagar a branch.
---

# Gitflow padrão dos projetos do Alessandro

**Toda tarefa nasce numa branch.** Nunca commitar direto na branch principal. Vale para código,
documentação, configuração e script, inclusive para mudança de uma linha.

Referência do modelo: [Gitflow (XP Inc.)](https://medium.com/xp-inc/trabalhando-com-o-gitflow-a8ae0e1ddaae).
Aqui ele vem **adaptado**: uma pessoa, deploy contínuo, sem `develop` e sem `release`.

## Antes de tudo: regra local do projeto prevalece

Esta skill é a regra geral. Alguns projetos têm a própria versão. Antes de aplicar esta, procure:

1. `.claude/skills/gitflow/SKILL.md` **no projeto**, como pasta real e não como link para o repo
   `claude-skills`. Existindo, leia e siga essa versão: ela traz escopos, script de deploy e estado das
   branches daquele projeto. O Claude Code mostra a skill pessoal no lugar da do projeto quando os
   nomes coincidem, por isso a leitura precisa ser explícita.
2. A seção de Git/branches do `CLAUDE.md`, `CLAUDE.local.md` ou `AGENTS.md` do projeto.

O que o projeto não definir segue o que está abaixo.

## Qual é a branch principal

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||'   # main ou master
```

Neste texto, `<principal>` é essa branch: ela é o que está em produção, recebe só merge e nunca
recebe commit direto. Não existe `develop`. Com um desenvolvedor e deploy frequente, ela só criaria um
desvio a mais.

## Branches de trabalho

| Prefixo | Para quê | Sai de | Volta para |
|---|---|---|---|
| `feature/` | funcionalidade nova, tela, integração | `<principal>` | `<principal>` |
| `fix/` | correção de bug | `<principal>` | `<principal>` |
| `hotfix/` | produção quebrada agora | `<principal>` | `<principal>`, com deploy imediato |
| `docs/` | só documentação, sem efeito em runtime | `<principal>` | `<principal>` |
| `chore/` | dependência, build, CI, limpeza | `<principal>` | `<principal>` |

**Nome:** prefixo + assunto curto em kebab-case, sem acento e sem número solto.
Exemplos: `fix/bug17-finaliza-pedido-rejeitado`, `feature/relatorio-mensal`, `hotfix/token-expirado`.
Se houver bug registrado no backlog, o número dele entra no nome.

**Branch de longa duração:** traga a `<principal>` para dentro dela com frequência
(`git merge <principal>`). Sem isso, o merge final vira um conflito só. Nunca faça o contrário.

## Ciclo de uma tarefa

```bash
# 1. sair sempre da principal atualizada
git switch <principal> && git pull --ff-only origin <principal>
git switch -c feature/assunto-curto

# 2. trabalhar em commits pequenos, cada um com uma ideia
git add <arquivos>            # nunca `git add -A` às cegas
git commit                    # mensagem no padrão abaixo

# 3. antes de fechar: testes da área alterada (skill testes-de-regressao)

# 4. fechar
git switch <principal> && git pull --ff-only origin <principal>
git merge --no-ff feature/assunto-curto
git push origin <principal>
# deploy: skill deploy-github-actions-ssh ou o script do projeto

# 5. apagar a branch já mesclada
git branch -d feature/assunto-curto
```

O `--no-ff` no merge é proposital: mantém visível na história o grupo de commits daquela tarefa.

## Mensagem de commit

Convencional, em português, no imperativo:

```
tipo(escopo): resumo em uma linha, minúsculo, sem ponto final

Corpo explicando o porquê, não o quê. O diff já diz o quê.
Cita o bug do backlog quando houver.
```

Tipos: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `security`.
Escopos: a área do projeto (`painel`, `api`, `web`, `deploy`, `bug N`…). O projeto pode fixar a lista.

**Autoria:** o commit sai só em nome do Alessandro (git user configurado). Nunca adicionar
`Co-Authored-By`, "Generated with…" nem qualquer menção a assistente de IA.

## Regras que não se negociam

1. **Nada de commit direto na `<principal>`.** Se aconteceu por engano e ainda não subiu:
   `git branch fix/assunto && git reset --hard origin/<principal> && git switch fix/assunto`.
2. **Nada de `git push --force` sem tag de backup antes** (`git tag backup/<branch>-AAAAMMDD`).
3. **Segredo nunca entra em commit:** `.env`, chave, token, `client_secret`, cookie. Confira o diff
   antes de cada commit, mesmo em repositório privado.
4. **Branch mesclada é apagada.** Branch abandonada ganha uma tag de backup antes de sumir.
5. **`hotfix/` fura a fila**, mas segue o mesmo caminho: branch, teste, merge, deploy. Nunca corrigir
   direto na produção pelo SSH, porque o próximo deploy sobrescreve a correção.
6. **Rebase só dentro da própria branch**, nunca em algo que já foi para o GitHub.
