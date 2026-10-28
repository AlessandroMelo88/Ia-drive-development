# claude-skills

Repositório central de TODAS as skills do Alessandro (próprias e de terceiros) para Claude Code, Codex e Gemini. Uma fonte só: perfis e
projetos recebem **symlinks** para cá. Por isso, editar uma skill em qualquer projeto edita este
repo, e a mudança chega a todos.

Desenho e motivos: `../MAPEAMENTO-SKILLS.md`.

## Estrutura

```
claude-skills/
├── perfis.yml           destinos das skills e regras globais (perfis Claude, ~/.agents, AGENTS.md, GEMINI.md)
├── externas.yml         skills de terceiros: origem e versão de cada uma (o conteúdo está em skills/externas/)
├── regras/
│   └── CLAUDE-global.md fonte de ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md e ~/.gemini/GEMINI.md
├── skills/
│   ├── global/          próprias, vão para TODOS os perfis e CLIs (checkpoint, testes, docs, padrões, gitflow...)
│   ├── externas/        de terceiros (strix, ui-ux-pro-max, playwright, impeccable, twg, graphify...), também globais
│   ├── deploy/          deploy-github-actions-ssh (+ modelos/)
│   └── stack/web/       validacao-visual
├── projetos/<nome>.yml  manifesto: quais skills (fora as globais) cada projeto recebe
└── bin/
    ├── instalar-perfis.sh   liga skills/global/* e as regras em todos os destinos de perfis.yml
    ├── instalar.sh          liga as skills do manifesto em <projeto>/.claude/skills
    ├── status.sh            o que está ligado, solto (cópia), divergente ou faltando
    ├── importar-externas.sh copia/atualiza skills de terceiros para skills/externas/
    └── promover.sh          traz uma skill de projeto/perfil para cá
```

O nome da pasta é o nome da skill. As categorias (`global/`, `deploy/`...) só organizam o repo, por
isso **o nome precisa ser único em todo o `skills/`**.

## Onde cada ferramenta lê

| Ferramenta | Skills | Regras globais |
|---|---|---|
| Claude Code (perfil padrão) | `~/.claude/skills/` | `~/.claude/CLAUDE.md` |
| Claude Code (`CLAUDE_CONFIG_DIR=~/.claude-<nome>`) | `~/.claude-<nome>/skills/` | herda `~/.claude/CLAUDE.md` (o Claude Code lê o `.claude/CLAUDE.md` das pastas acima do projeto) |
| Codex CLI | `~/.agents/skills/` (padrão aberto Agent Skills; `~/.codex/skills` é o local antigo) | `~/.codex/AGENTS.md` |
| Gemini CLI | `~/.agents/skills/` e `~/.gemini/skills/` (o primeiro vence em conflito) | `~/.gemini/GEMINI.md` |
| Projeto (qualquer perfil) | `<projeto>/.claude/skills/` | `CLAUDE.md`/`AGENTS.md` do projeto |

Codex e Gemini têm skills nativas no mesmo formato (`SKILL.md` com frontmatter), então recebem as
mesmas pastas, sem conversão. Os dois leem `~/.agents/skills`. Um destino só evita skill duplicada.

**Precedência no Claude Code:** skill pessoal (perfil) vence a do projeto quando o nome é igual. Por
isso:
- as globais vão só para os perfis;
- `gitflow` e `escopo-comercial` globais mandam ler primeiro a versão local do projeto, quando ela
  existir.

## Máquina nova (depois do `git clone`)

```bash
git clone <url-do-repo> ~/develop/server/wordpress/Ia-drive-development/claude-skills   # ou qualquer pasta
cd claude-skills
bin/instalar-perfis.sh --simular     # mostra o que faria
bin/instalar-perfis.sh               # liga globais + regras
bin/instalar.sh feebapp              # por projeto (caminho do manifesto, com ~)
bin/instalar.sh feebapp /outro/caminho/feebapp   # se o projeto estiver em outro lugar
bin/status.sh
```

- Nenhum script tem caminho fixo do Mac. A raiz do repo é descoberta pelo próprio script, e os
  destinos vêm do `$HOME` (`perfis.yml` usa `~` e `*`).
- O repo pode ficar em qualquer pasta. Os symlinks são criados na hora com o caminho daquela máquina.
  Se mover o repo, rode os instaladores de novo.
- Perfil novo do Claude Code (`~/.claude-<nome>` com `projects/`, `history.jsonl` ou `skills/`) entra
  sozinho na próxima instalação. Pasta que não é perfil vai em `ignorar:` no `perfis.yml`.
- CLI não instalado (sem `~/.codex` ou `~/.gemini`): a regra dele é pulada.
- `validacao-visual` usa Playwright: rode `npm install` em `skills/stack/web/validacao-visual/`
  (o `node_modules` não é versionado).
- Requisitos: bash (3.2 do macOS serve), git 2.31+, rsync, diff.

## Segurança dos instaladores

- **Nunca apagam.** O que já existia com o nome de uma skill global (pasta real, arquivo, link para
  outro lugar) é **movido** para `<perfil>/skills-backup-<AAAAMMDD>/`. `DATA_BACKUP=AAAAMMDD` fixa a
  data.
- Não tocam em outras skills, em `synced/` (Claude.ai) nem em plugins.
- O `instalar.sh` só cria links em `<projeto>/.claude/skills/` e acrescenta a linha
  `/.claude/skills/<nome>` ao `.git/info/exclude` do projeto (local, nunca commitado). Se já existir
  uma pasta real com o mesmo nome no projeto, ele para e avisa.
- Os dois instaladores aceitam `--simular`.

## Fluxo: editei a skill no projeto X, como chega no Y

1. No projeto X, o Claude edita `.claude/skills/<skill>/SKILL.md` (ou `~/.claude/skills/<skill>/...`).
   É um symlink, então **o arquivo alterado é o deste repo**.
2. O `git status` do projeto X não mostra nada, por causa do exclude. Aqui, `bin/status.sh` mostra a
   mudança em "Mudanças não commitadas".
3. Commite **aqui**: `git commit -m "feat(testes-de-regressao): ..."` e uma linha no `CHANGELOG.md`.
   Mudança grande ganha tag (`git tag v1.1.0`).
4. O projeto Y na mesma máquina já vê a mudança na próxima sessão (é o mesmo arquivo). Em outra
   máquina: `git pull` aqui.
5. Se Y ainda não recebe a skill: acrescente ao `projetos/Y.yml` e rode `bin/instalar.sh Y`.

Regra para os agentes (está em `regras/CLAUDE-global.md`): **editou uma skill que é link para
`claude-skills`? Commite no repo central, nunca no projeto.**

## Skills externas (de terceiros)

Ficam versionadas em `skills/externas/<nome>/` e vão para todos os perfis como as globais.
`externas.yml` guarda a origem e a versão de cada uma.

- **Uma cópia por skill.** Nomes extras são `aliases:` no `perfis.yml` (`strix` →
  penetration-testing-with-strix, `playwright` → playwright-skill), ligados só nos perfis do Claude Code.
- **impeccable tem uma variante por ferramenta:** `externas/impeccable` (Claude) e
  `externas/impeccable-agents` (Codex/Gemini). `sobreposicoes:` no `perfis.yml` faz
  `~/.agents/skills/impeccable` apontar para a variante agents. A pasta `impeccable-agents` não vira
  link com o próprio nome (`nao_ligar:`).
- **twg\*:** uma cópia só. O `.twg-install.json` (caminho e horário locais do instalador) fica fora do
  git.
- Lixo gerado (`__pycache__`, `*.pyc`, `.coverage`, `node_modules`) não é importado nem versionado.
- Fora do repo, sem mexer: `synced/` (Claude.ai) e skills de plugins.

**Atualizar uma externa:**

```bash
npx skills add usestrix/strix          # ou o instalador da skill (npx impeccable, twg...)
bin/importar-externas.sh penetration-testing-with-strix   # copia a versão nova para skills/externas/
git diff skills/externas/              # revise; ajuste a versão em externas.yml; commite
bin/instalar-perfis.sh                 # a cópia que o instalador deixou no perfil vai para o backup e vira link
```

Se o instalador escrever através do link (direto no repo), o `importar-externas.sh` avisa
"no-repo"; nesse caso basta revisar o `git diff`. Externa nova: registre a linha em `externas.yml`
e rode o mesmo fluxo.

## Skill nova ou promovida

```bash
bin/promover.sh <pasta-da-skill> global        # ou deploy, stack/web, ...
# generalize o SKILL.md (sem dado de cliente), commite, depois:
bin/instalar-perfis.sh                          # se global
# ou acrescente ao projetos/<p>.yml e: bin/instalar.sh <p>
```

## Versionamento

- O histórico do git é a versão. `CHANGELOG.md` registra uma linha por mudança de skill.
- Tags semânticas (`v1.0.0`) marcam mudanças que alteram comportamento.
- Os links apontam para a cópia de trabalho (HEAD). Para congelar um projeto numa versão: crie um
  `git worktree add ../claude-skills-v1.0.0 v1.0.0` e rode o `bin/instalar.sh <p>` **de dentro do
  worktree** (os links passam a apontar para ele). Nesse modo a edição não volta para o repo.
