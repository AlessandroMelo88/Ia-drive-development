# Mapeamento de skills — repositório central (desenho)

> Documento de desenho, sem implementação. Levantamento feito em 2026-10-28.
> Nada foi movido, apagado, editado ou commitado. Valores de `.env` e segredos não foram copiados aqui.
> Observação: a pasta real é `Ia-drive-development` (com **I** maiúsculo), não `la-drive-development`.

---

## 1. Inventário

### 1.1 Perfis encontrados

| Perfil | `skills/` | `CLAUDE.md` próprio |
|---|---|---|
| `~/.claude` | 50 entradas (skills do Alessandro, de terceiros e links) | sim (regras globais) |
| `~/.claude-ricardo` | `code-mode` + `synced/` | não |
| `~/.claude-kpa` | `code-mode` | não |
| `~/.claude-mem` | não é perfil (sem `skills/`) | — |

**Achado importante:** os perfis `ricardo` e `kpa` **não têm** `checkpoint-projeto`, `testes-de-regressao`, `docs-first` etc. O `~/.claude/CLAUDE.md` exige essas skills, e esse arquivo chega a esses perfis só porque fica numa pasta acima dos projetos: o Claude Code lê `<pasta-ancestral>/.claude/CLAUDE.md` como instrução de projeto. Resultado: a regra chega, mas a skill que ela manda usar não existe naquele perfil. Por exemplo, nesta sessão (perfil `ricardo`) `checkpoint-projeto` e `testes-de-regressao` não aparecem na lista de skills.

### 1.2 Skills do Alessandro (autoria própria — vão para o repo central)

| Skill | Onde está | Descrição (1 linha) | Situação |
|---|---|---|---|
| `checkpoint-projeto` | `~/.claude` | Manter `Docs/ESTADO-DO-PROJETO.md` (produção, feito, em aberto, para onde vamos) | só no perfil padrão |
| `testes-de-regressao` | `~/.claude` | Todo bug vira teste que falha antes e passa depois; regra de negócio vira teste | só no perfil padrão; vai ganhar a camada de deploy |
| `docs-first` | `~/.claude` | Consultar a doc oficial da versão exata antes de codar; preferir recurso nativo | só no perfil padrão |
| `documentacao-viva` | `~/.claude` | Atualizar a documentação a cada mudança de comportamento | só no perfil padrão |
| `padroes-projeto` | `~/.claude` | ADR, spec por feature, padrão de arquitetura dos projetos do Alessandro | só no perfil padrão |
| `painel-kit` | `~/.claude` | Bootstrap de projeto novo com painel administrativo | só no perfil padrão |
| `validacao-visual` | `~/.claude` | Validação visual no app local (tela, clique, redirect, texto) | só no perfil padrão |
| `code-mode` | `~/.claude-ricardo`, `~/.claude-kpa` | Escrever script em vez de encadear muitas chamadas MCP | **idêntica** nos dois (hash `9b2be0dd`); **ausente** no `~/.claude` |
| `busca-vagas` | link `~/.claude` → `alessandro/.claude/skills` | Busca e pontua vagas para o perfil do Alessandro | pessoal; já usa link para o projeto |
| `post-tech` | link `~/.claude` → `alessandro/.claude/skills` | Pauta de tecnologia e rascunho de post | pessoal; já usa link para o projeto |

### 1.3 Skills de terceiros (não vão para o repo; só referenciadas)

Origem registrada em `~/.agents/.skill-lock.json` (CLI `skills`) e em `~/.claude/skills/SKILLS-ORIGEM.tsv`.

| Grupo | Skills | Origem | Observação |
|---|---|---|---|
| Strix (segurança) | `api-security-testing`, `application-security-testing`, `ci-security-scanning-with-strix`, `find-security-vulnerabilities-in-code`, `fix-security-vulnerabilities-with-strix`, `managed-pentesting-with-strix`, `owasp-top-10-testing`, `penetration-testing-with-strix`, `web-app-penetration-testing` | `usestrix/strix` | links para `~/.agents/skills`. **Duplicata:** `strix` e `penetration-testing-with-strix` apontam para a mesma pasta |
| UI/UX Pro Max | `banner-design`, `brand`, `design`, `design-system`, `slides`, `ui-styling`, `ui-ux-pro-max` | `nextlevelbuilder/ui-ux-pro-max-skill` | links para `~/.agents/skills` |
| Playwright | `playwright`, `playwright-skill` | `testdino-hq/playwright-skill` | **Duplicata:** os dois links apontam para a mesma pasta |
| Playwright CLI | `playwright-cli` | `microsoft/playwright-cli@b1a5903` | cópia local |
| Outras | `context7` (`intellectronica/agent-skills`), `find-skills` (`vercel-labs/skills`), `taste-skill` (`Leonxlnx/taste-skill`), `image-to-code` (`Leonxlnx/imagegen-skills`), `web-design-guidelines` (`vercel-labs/agent-skills`), `awesome-design` (`VoltAgent/awesome-design-md`), `graphify` | várias | cópias locais |
| `impeccable`, `twg*` (13 skills Atlassian) | — | `~/.agents/skills` + cópia em `~/.claude/skills` | **Divergentes:** a cópia em `~/.claude/skills` difere da de `~/.agents/skills` (ex.: `impeccable` `9f1dd474` × `72c26d96`; `twg` `1ed82242` × `99241daa`; `twg-jira` `503445c1` × `f92b1259`). Aqui são pastas reais, não links |
| `synced/<bucket>/` | `brand-guidelines`, `docx`, `pdf`, `pptx`, `xlsx`, `skill-creator`, `mcp-builder` etc. (18) | sincronizadas pelo Claude.ai (organização) | em `~/.claude` e `~/.claude-ricardo`; diferem só em `computer-use/SKILL.md`, `xlsx/scripts/recalc.py` e `manifest.json` (diferença de rodada de sync). **Não mexer:** são gerenciadas pela plataforma |

### 1.4 Skills locais de projeto (`<projeto>/.claude/skills`)

| Projeto | Skill | Descrição | Candidata a compartilhada? |
|---|---|---|---|
| canaldecortes | `finalizar-e-deploy` | Fechar branch, testar, merge, push, deploy, conferir versão no ar | **Sim:** base da `deploy-github-actions-ssh` |
| canaldecortes | `gitflow` | Branches, commits e PRs do Canal de Cortes | talvez (gitflow genérico) |
| Jeferson-apostas | `escopo-comercial` | Classificar mudanças na `main` como escopo ou extra (`Docs/comercial/`) | **Sim**, para projetos de cliente |
| riodelux | `fleet-ui` | Regras de UI do front whitelabel Fleet UI | não (específica) |
| traider | `b3-analise-tecnica`, `compliance-cvm`, `traider-quant-dev` | Domínio B3, guarda-corpo CVM 598/20, postura técnica | não (específicas) |
| alessandro | `busca-vagas`, `post-tech` | Pessoais | não (pessoal) |

---

## 2. Projetos

Repos git em `/Users/alessandrobm1/develop/server/wordpress/*`. Nenhum item no primeiro nível de `/Users/alessandrobm1/develop/*` é repo git.

| Projeto | Stack | Deploy | `.claude/skills` | CLAUDE / AGENTS | ESTADO-DO-PROJETO |
|---|---|---|---|---|---|
| feebapp | Next (`web/`) + Laravel (`backend/`) + `agente-a3` | **GH Actions** `ci.yml`, `deploy.yml` (ssh, build no runner, troca de release, checagem de saúde), `e2e-producao.yml`; `bin/publicar.sh`, `bin/deploy-backend.sh`, `bin/deploy-agendado.sh` | — | só AGENTS | sim |
| Jeferson-apostas | Laravel + front Node | **GH Actions** `ci.yml` + `deploy.yml` (ssh, backup do Postgres, `./deploy.sh` no servidor, confere sha) | `escopo-comercial` | CLAUDE + AGENTS (+ `CLAUDE.local.md`) | sim |
| canaldecortes | Python (workers) + Laravel (`painel/`) + Docker | GH Actions só `ci.yml`; deploy por `deploy.sh` + skill `finalizar-e-deploy` | `finalizar-e-deploy`, `gitflow` | CLAUDE | sim |
| barbosabebidas | Next (`app/`) + Laravel (`backoffice/`) + Docker | sem workflow; `bin/deploy.sh` roda **no servidor** (git pull, build, restart) | — | CLAUDE + AGENTS | sim |
| umbrella-solutions | Next (`web/`) + Docker (`deploy/`) | sem workflow | — | CLAUDE | sim |
| chamaprofissa | LP/estático + `deploy/setup-vps.sh` | sem workflow | — | CLAUDE + AGENTS | não |
| riodelux | Laravel (`backend/`) + Next (`backoffice-app/`) + Tauri | sem workflow | `fleet-ui` | CLAUDE | não |
| traider | Django (Python) | sem workflow | 3 locais | CLAUDE | não |
| feeb | PHP legado + Node (gulp) | sem workflow | — | CLAUDE | não |
| alessandro | Node (portfólio, painel, scripts) | sem workflow | `busca-vagas`, `post-tech` | — | não |
| placebeads | só `Docs/` | — | — | — | não |

Padrão de deploy comum (feebapp e Jeferson-apostas, os dois mais maduros):
- `workflow_dispatch` com confirmação digitada (`PUBLICAR`) para produção;
- segredos `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS` e `DEPLOY_SSH`; `~/.ssh/config` com `Host deploy` e `StrictHostKeyChecking yes`;
- CI reutilizado antes do deploy, deploy por ssh e conferência do sha publicado.

---

## 3. Estrutura proposta

Proposta: repo `Ia-drive-development/claude-skills/` (subpasta, para não misturar com `instagram/`). Ver dúvida 1.

```
claude-skills/
├── README.md                  # como instalar, editar e publicar
├── CHANGELOG.md               # uma linha por mudança de skill (vira a nota da tag)
├── perfis.yml                 # quais ~/.claude* recebem as skills globais
├── externas.yml               # terceiros: nome, origem@commit, comando de instalação (não versiona o conteúdo)
├── regras/
│   └── CLAUDE-global.md       # fonte do ~/.claude/CLAUDE.md (checkpoint, testes, autoria)
├── skills/
│   ├── global/                # linkadas em TODOS os perfis; valem em qualquer pasta
│   │   ├── checkpoint-projeto/
│   │   ├── testes-de-regressao/
│   │   ├── docs-first/
│   │   ├── documentacao-viva/
│   │   ├── padroes-projeto/
│   │   ├── painel-kit/        # precisa ser global: roda antes de o projeto existir
│   │   └── code-mode/
│   ├── deploy/
│   │   └── deploy-github-actions-ssh/
│   │       ├── SKILL.md
│   │       └── modelos/       # deploy.yml, checar-env.sh, smoke.sh (modelos, sem segredos)
│   ├── stack/
│   │   ├── web/validacao-visual/
│   │   ├── laravel/           # (futuro) convenções Laravel comuns a 5 projetos
│   │   └── next/              # (futuro)
│   ├── cliente/
│   │   └── escopo-comercial/  # promovida do Jeferson-apostas (se aprovado)
│   └── pessoal/
│       ├── busca-vagas/
│       └── post-tech/
├── projetos/
│   ├── feebapp.yml
│   ├── jeferson-apostas.yml
│   └── ...                    # um manifesto por projeto
└── bin/
    ├── instalar.sh            # instalar.sh <projeto> | --todos
    ├── instalar-perfis.sh     # liga skills/global em cada perfil de perfis.yml
    ├── status.sh              # mudanças não commitadas + links quebrados/ausentes
    └── promover.sh            # traz uma skill local de projeto para o repo central
```

Regras da estrutura:
- O nome da pasta da skill é o nome dela no Claude Code. As subpastas (`global/`, `stack/`…) só organizam o repo, porque o link achata tudo em `.claude/skills/<nome>`. Por isso o nome de cada skill precisa ser único em todo o repo.
- Uma skill exclusiva de um projeto (`fleet-ui`, `traider-*`, `gitflow`) **continua no repo do projeto**, versionada junto com o código, e aparece no manifesto como `locais:` só para inventário. Ela vai para o repo central quando um segundo projeto precisar dela (`promover.sh`).
- `global/` vai só para os perfis, e não também para os projetos. Assim nunca há duas skills com o mesmo nome visíveis ao mesmo tempo.

Exemplo de manifesto `projetos/feebapp.yml`:

```yaml
projeto: feebapp
caminho: /Users/alessandrobm1/develop/server/wordpress/feebapp
stack: [next, laravel]
deploy: github-actions-ssh
skills:                       # além das globais, que já vêm pelo perfil
  - deploy/deploy-github-actions-ssh
  - stack/web/validacao-visual
locais: []                    # skills que vivem em feebapp/.claude/skills (só inventário)
```

`perfis.yml`:

```yaml
perfis:
  - ~/.claude
  - ~/.claude-ricardo
  - ~/.claude-kpa
global: skills/global/*
```

---

## 4. Distribuição (recomendação)

### 4.1 Opções comparadas

| Critério | A. Symlinks só nos perfis (`~/.claude*/skills/<nome>` → repo) | **B. `instalar.sh <projeto>` com symlinks no projeto + globais nos perfis** | C. Plugin marketplace do Claude Code (repo GitHub com `.claude-plugin/marketplace.json`; o projeto habilita em `.claude/settings.json`) |
|---|---|---|---|
| Vários perfis `~/.claude*` | precisa ligar cada perfil | as globais vão por `perfis.yml`; as do projeto valem em **qualquer** perfil, porque ficam no projeto | cada perfil instala o plugin; `extraKnownMarketplaces` no projeto sugere a instalação |
| Escolher skills por projeto | **não** (tudo em todo lugar) | **sim** (manifesto) | sim (habilita plugins por projeto), mas a granularidade é o plugin, não a skill |
| Edição no projeto volta ao repo central | sim (o link grava no repo) | **sim** (o link grava no repo) | **não**: o plugin é uma cópia em cache; é preciso editar no repo, subir a versão e rodar `/plugin marketplace update` |
| Versionamento | git do repo central | git do repo central + tags; congelar versão é opcional | `version` no `plugin.json`; o mais formal |
| Outra máquina, servidor, colaborador | só com clone + script | só com clone + script; os links são locais e não vão para o git do projeto | **funciona** em qualquer lugar a partir do GitHub |
| Esforço | mínimo | baixo (3 scripts curtos) | médio (estrutura de plugin; skills com prefixo `plugin:skill`) |

Descartada: **git submodule/subtree**. Seriam 11 cópias do repo, uma por projeto, cada uma atualizada à mão. A edição feita no projeto exige commit dentro do submódulo, e esse é exatamente o atrito que se quer eliminar.

### 4.2 Recomendação: opção B

`instalar.sh` lê `projetos/<nome>.yml` e, para cada skill listada:
1. cria `<projeto>/.claude/skills/<nome>` como **symlink** para `claude-skills/skills/.../<nome>` (nunca cópia);
2. adiciona `.claude/skills/<nome>` ao `.git/info/exclude` do projeto, que é local e não é commitado: o link absoluto não vai para o GitHub do projeto nem para o servidor;
3. não toca em skills locais reais (pastas que não são link). Se o nome colidir, para e avisa.

`instalar-perfis.sh` liga `skills/global/*` em cada perfil de `perfis.yml`. Isso corrige a falta de `checkpoint-projeto` e `testes-de-regressao` nos perfis `ricardo` e `kpa`.

Por que B:
- É a única opção que atende juntas as três exigências: perfis múltiplos, seleção por projeto e **edição no projeto que volta ao central sem passo extra**.
- O Claude Code já segue skills em symlink nesta máquina: `~/.claude/skills` usa links para `~/.agents/skills` e para `alessandro/.claude/skills`, e elas funcionam.

Quando migrar para C: se um colaborador, outra máquina ou o servidor precisar das skills. O repo já nasce no formato certo (uma pasta por skill), e dá para acrescentar o `marketplace.json` depois sem reorganizar.

### 4.3 Fluxo "editei a skill no projeto X → chega no Y"

Exemplo: camada de deploy na `testes-de-regressao`.

1. No feebapp (projeto X), o Claude edita `.claude/skills/deploy-github-actions-ssh/SKILL.md`, ou `~/.claude/skills/testes-de-regressao/SKILL.md` se for global. Como é symlink, **o arquivo alterado é o do repo central**.
2. `git status` no feebapp não mostra nada, porque o link está no exclude. Em `claude-skills/`, `git status` (ou `bin/status.sh`) mostra a mudança.
3. Commit e push no repo central: `feat(testes-de-regressao): camada de deploy (.env obrigatório + smoke pós-deploy)` e uma linha no `CHANGELOG.md`. Se a mudança for grande, criar uma tag (`v1.4.0`).
4. O projeto Y, na mesma máquina, já enxerga a mudança na próxima sessão, porque é o mesmo arquivo. Em outra máquina: `git pull` em `claude-skills/`.
5. Se Y ainda não recebe essa skill: acrescentar uma linha em `projetos/Y.yml` e rodar `bin/instalar.sh Y`.

Para não esquecer o passo 3, há duas proteções (uma ou as duas):
- uma regra em `regras/CLAUDE-global.md`: "Editou uma skill que é symlink para `claude-skills`? Commite no repo central, nunca no projeto.";
- um hook `Stop` no `settings.json` dos perfis que roda `bin/status.sh` e avisa quando há mudança não commitada no repo central.

Versão congelada (opcional, só se um projeto precisar ficar parado numa versão): `instalar.sh <projeto> --ref v1.3.0` cria um `git worktree` em `claude-skills/.versoes/v1.3.0/` e liga o projeto ali. Nesse modo a edição não volta ao central; por isso o padrão continua sendo HEAD.

### 4.4 Regras globais (`~/.claude/CLAUDE.md`)

Guardar a fonte em `regras/CLAUDE-global.md` e fazer `~/.claude/CLAUDE.md` virar um symlink para ela. Hoje, nos perfis `ricardo` e `kpa`, essa regra só chega porque o arquivo fica numa pasta acima dos projetos. Criar `~/.claude-ricardo/CLAUDE.md` também faria a regra ser lida duas vezes nos projetos dentro de `~`. Ver dúvida 4.

### 4.5 Terceiros

As skills de terceiros não entram no repo. `externas.yml` registra o nome, a origem@commit e o comando de instalação (`npx skills add …`), unificando `SKILLS-ORIGEM.tsv` e `.skill-lock.json`. As skills `synced/` do Claude.ai ficam fora de tudo.

---

## 5. Mapeamento inicial

Todas as skills **globais** (`checkpoint-projeto`, `testes-de-regressao`, `docs-first`, `documentacao-viva`, `padroes-projeto`, `painel-kit`, `code-mode`) chegam a todos os projetos pelo perfil. A tabela lista só o que vai pelo manifesto.

| Projeto | Skills do manifesto | Locais (ficam no projeto) | Motivo |
|---|---|---|---|
| feebapp | `deploy-github-actions-ssh`, `validacao-visual` | — | é o deploy de referência (build no runner, release, e2e em produção); tem front Next |
| Jeferson-apostas | `deploy-github-actions-ssh`, `validacao-visual`, `escopo-comercial` (se promovida) | `escopo-comercial` (até ser promovida) | mesmo padrão ssh + backup do banco; projeto de cliente |
| canaldecortes | `deploy-github-actions-ssh` | `finalizar-e-deploy`, `gitflow` | a `finalizar-e-deploy` passa a delegar o passo de deploy e smoke para a skill comum; o CI já existe, falta o deploy por Actions |
| barbosabebidas | `deploy-github-actions-ssh`, `validacao-visual` | — | hoje faz deploy manual no servidor; a skill guia a migração para Actions |
| umbrella-solutions | `deploy-github-actions-ssh`, `validacao-visual` | — | Next + Docker sem workflow |
| chamaprofissa | `deploy-github-actions-ssh`, `validacao-visual` | — | LP com VPS; ganha deploy padronizado |
| riodelux | `deploy-github-actions-ssh`, `validacao-visual` | `fleet-ui` | Laravel + Next; UI própria |
| traider | `deploy-github-actions-ssh` (se for para o servidor) | `b3-analise-tecnica`, `compliance-cvm`, `traider-quant-dev` | domínio próprio; Django |
| feeb | — | — | legado; só as globais até haver plano de deploy |
| alessandro | `busca-vagas`, `post-tech` | — | pessoais; hoje são reais no projeto e linkadas no perfil. Com o repo central, a fonte passa a ser o central |
| placebeads | — | — | só documentação por enquanto |

---

## 6. Esqueleto proposto: `deploy-github-actions-ssh`

Proposta de conteúdo (tópicos), baseada no `deploy.yml` do feebapp e do Jeferson-apostas e na `finalizar-e-deploy` do canaldecortes.

**Frontmatter (rascunho)**
- `name: deploy-github-actions-ssh`
- `description:` usar SEMPRE que for publicar, configurar ou depurar o deploy de um projeto do Alessandro (GitHub Actions + ssh para servidor próprio); também em "subir", "publicar", "deploy", "pôr no ar".

**1. Contrato do padrão**
- O deploy roda por `workflow_dispatch`, com ambiente `stage|prod`. Produção exige a confirmação digitada `PUBLICAR`.
- Segredos do repo (só os nomes): `DEPLOY_SSH_KEY` (chave exclusiva do CI), `DEPLOY_KNOWN_HOSTS` (host fixado), `DEPLOY_SSH` (`usuario@host`).
- `~/.ssh/config` do runner: `Host deploy`, `IdentitiesOnly yes`, `StrictHostKeyChecking yes`, `ConnectTimeout`.
- O CI (`ci.yml`) é chamado com `uses:` antes do deploy. Se o CI está vermelho, não há deploy.

**2. Pré-deploy: `.env` obrigatório** (camada nova pedida para a `testes-de-regressao`)
- A lista das chaves obrigatórias por ambiente fica versionada no projeto (`deploy/env-obrigatorio.txt` ou `.env.example`).
- `checar-env.sh` roda **no servidor via ssh**. Ele compara só os **nomes** das chaves presentes no `.env` do servidor com a lista e falha se faltar alguma.
- Nunca imprimir valores no log. Nunca copiar `.env` pelo CI.
- Backup do banco antes de migração, com teste de integridade do arquivo (padrão do Jeferson: `gunzip -t`).

**3. Publicação**
- Duas variantes: (a) build no runner, envio do artefato e troca de release por link (feebapp: o servidor não compila); (b) `git pull` + script no servidor (Jeferson, barbosabebidas).
- Só publicar o que mudou: guardar no servidor o sha publicado por parte (web/backend).
- Migração com modo manutenção. Rollback = reativar a release ou o sha anterior.

**4. Pós-deploy: smoke test** (segunda camada nova)
- Conferir que o sha no servidor é igual ao sha publicado.
- `smoke.sh <url-base>`: lista de URLs críticas versionada no projeto. Exigir status 200, um texto esperado na página e o endpoint de saúde/versão.
- Containers de pé (`docker ps` filtrado). O e2e de produção é opcional (`e2e-producao.yml` do feebapp).
- Se o smoke falhar, o job fica vermelho e o rollback é indicado. Falha silenciosa vira falha alta, como na Regra 4 da `testes-de-regressao`.

**5. Configurar um projeto novo**
- Checklist: gerar a chave de deploy, fixar o `known_hosts`, cadastrar os segredos e copiar `modelos/deploy.yml`.
- Também: criar `env-obrigatorio.txt` e a lista do smoke, e rodar a primeira vez em `stage`.

**6. Relatório pós-deploy**
- O que subiu (sha, partes), resultado do `.env` e do smoke, e onde ficou o backup.
- Atualizar `Docs/ESTADO-DO-PROJETO.md` (integra com a `checkpoint-projeto`).

**7. Anti-padrões**
- Rodar `npm install`/build em produção quando a variante é "build no runner".
- `StrictHostKeyChecking no`.
- Imprimir segredo no log.
- Deploy de commit que não está no GitHub.
- Pular o smoke porque "só mudou CSS".

**Divisão com `testes-de-regressao`:** a `testes-de-regressao` ganha a "camada 4 — deploy" como regra (o que precisa existir: checagem de `.env` e smoke). A `deploy-github-actions-ssh` traz o como (scripts, workflow). Uma referencia a outra, sem duplicar texto.

---

## 7. Próximos passos

1. Responder às dúvidas abaixo.
2. Criar `Ia-drive-development/claude-skills/` com `git init`. **Copiar**, sem mover, as skills de autoria própria (seção 1.2).
3. Escrever `bin/instalar-perfis.sh`. Ligar `global/` em `~/.claude-ricardo` e `~/.claude-kpa` primeiro, porque lá elas faltam. Depois trocar as pastas reais de `~/.claude/skills` pelos links, com backup.
4. Escrever `bin/instalar.sh` e `bin/status.sh`. Testar no feebapp com `deploy-github-actions-ssh`.
5. Escrever a `deploy-github-actions-ssh` (seção 6) e a camada 4 da `testes-de-regressao`. Validar no feebapp e depois no Jeferson-apostas.
6. Criar os manifestos `projetos/*.yml` a partir da seção 5 e rodar `instalar.sh --todos`.
7. Fazer a limpeza separadamente, com confirmação: remover os links duplicados (`strix`, `playwright`) e decidir qual cópia de `impeccable`/`twg*` vale.
8. Subir o repo no GitHub (privado). Avaliar a opção C (marketplace) só quando outra máquina ou um colaborador precisar.

## Dúvidas para o Alessandro

1. O repo fica na própria `Ia-drive-development/` (convivendo com `instagram/`) ou numa subpasta `Ia-drive-development/claude-skills/`? E o nome é mesmo `Ia-drive-development` (com I maiúsculo)?
2. Os perfis `ricardo` e `kpa` devem receber todas as skills globais, ou algum perfil é de cliente e deve ficar restrito?
3. A `escopo-comercial` (Jeferson) vale para todos os projetos de cliente? A `gitflow` (canaldecortes) vira padrão geral?
4. As regras globais devem ficar só em `~/.claude/CLAUDE.md` (hoje chegam aos outros perfis por estarem numa pasta acima dos projetos) ou ganhar um link em cada perfil?
5. As skills de outros projetos precisam estar disponíveis no servidor, em outra máquina ou para outra pessoa? Se sim, a opção C entra mais cedo.
6. `impeccable` e `twg*` divergem entre `~/.agents/skills` e `~/.claude/skills`: qual cópia é a atual?
7. O feebapp tem só `AGENTS.md`. Quer um `CLAUDE.md` com `@AGENTS.md`, como nos outros projetos?
