# Pendente de decisão: `impeccable` e `twg*`

Cópias lado a lado para o Alessandro decidir. **Nada foi escolhido nem apagado.** As originais
continuam onde estavam. As cópias desta pasta ficam **fora do git** (`.gitignore`, cerca de 10 MB de
skill de terceiro). Só este README é versionado.

Comparação feita em 2026-10-28 com `diff -r`.

## impeccable (terceiro, `npx impeccable`)

| Cópia | Origem | Arquivos | Versão | Data mais recente |
|---|---|---|---|---|
| `impeccable/agents-skills/` | `~/.agents/skills/impeccable` | 152 | 4.0.4 | 2026-08-12 |
| `impeccable/claude-skills/` | `~/.claude/skills/impeccable` | 147 | 4.0.4 | 2026-08-12 |
| `impeccable/gemini-skills/` | `~/.gemini/skills/impeccable` | 147 | 4.0.4 | 2026-08-12 |

**Leitura:** não são versões diferentes. É a mesma versão (4.0.4, mesma data), gerada pelo instalador
para cada ferramenta. As diferenças são todas de adaptação:
- Claude: `/impeccable`, `AskUserQuestion`, `.claude/skills/...` e frontmatter com `allowed-tools` e
  `argument-hint`.
- Codex (`~/.agents`): `$impeccable`, "Codex's structured user-input tool", `.agents/skills/...` e a
  pasta `agents/` com 5 arquivos (`*.toml`, `openai.yaml`) a mais.
- Gemini: `.gemini/skills/...`.

A "mais completa" em número de arquivos é a de `~/.agents` (+5 arquivos), mas os 5 só servem ao
Codex. **Cada cópia é a correta para a sua ferramenta.** Unificar quebraria as outras.

Observação: o Gemini lê `~/.agents/skills` e `~/.gemini/skills`, e avisa
`Skill conflict detected: "impeccable"` (a de `~/.agents` vence). Se quiser silenciar o aviso, a
cópia de `~/.gemini/skills` é a redundante.

## twg* (Atlassian Teamwork Graph, 13 skills)

| Cópia | Origem | Data |
|---|---|---|
| `twg/<skill>/agents-skills/` | `~/.agents/skills/<skill>` | instalada em 2026-10-16T03:12:49.263Z |
| `twg/<skill>/claude-skills/` | `~/.claude/skills/<skill>` | instalada em 2026-10-16T03:12:49.305Z |

**Leitura:** conteúdo **idêntico** nas 13 skills. A única diferença é o `.twg-install.json` (metadado
do instalador: `target` "global" × "Claude Code", `installPath` e o horário, 42 ms de diferença).
Nenhuma é mais nova nem mais completa. Foram instaladas pelo mesmo comando para os dois destinos.

## O que falta decidir

1. Manter as cópias por ferramenta como estão (recomendação técnica: sim, é como os instaladores
   funcionam) ou reinstalar só num lugar.
2. Remover ou não `~/.gemini/skills/impeccable` (redundante para o Gemini).
3. Depois da decisão, apagar esta pasta (as cópias aqui são só para comparação).
