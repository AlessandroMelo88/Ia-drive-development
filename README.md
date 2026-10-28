# claude-skills

Repositório central das skills do Alessandro para Claude Code, Codex e Gemini. Uma fonte só: perfis e
projetos recebem **symlinks** para cá. Por isso, editar uma skill em qualquer projeto edita este
repo, e a mudança chega a todos.

Desenho e motivos: `../MAPEAMENTO-SKILLS.md`.

## Estrutura

```
claude-skills/
├── perfis.yml           destinos das skills e regras globais (perfis Claude, ~/.agents, AGENTS.md, GEMINI.md)
├── externas.yml         skills de terceiros: só a origem, para reinstalar (conteúdo não versionado)
├── regras/
│   └── CLAUDE-global.md fonte de ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md e ~/.gemini/GEMINI.md
├── skills/
│   ├── global/          vão para TODOS os perfis e CLIs (checkpoint, testes, docs, padrões, gitflow...)
│   ├── deploy/          deploy-github-actions-ssh (+ modelos/)
│   └── stack/web/       validacao-visual
├── projetos/<nome>.yml  manifesto: quais skills (fora as globais) cada projeto recebe
├── pendente-decisao/    impeccable e twg* lado a lado (só o README é versionado)
└── bin/
    ├── instalar-perfis.sh   liga skills/global/* e as regras em todos os destinos de perfis.yml
    ├── instalar.sh          liga as skills do manifesto em <projeto>/.claude/skills
    ├── status.sh            o que está ligado, solto (cópia), divergente ou faltando
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
