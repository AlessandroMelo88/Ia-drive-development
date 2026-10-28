# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# Checkpoint do projeto
Todo projeto mantém `Docs/ESTADO-DO-PROJETO.md`: onde estamos, o que está em aberto e para onde vamos. Na primeira resposta de cada sessão, se o arquivo existir, leia-o e abra com um overview curto que liga o pedido à seção "Para onde vamos"; ao terminar uma rodada, atualize-o. Procedimento completo, e como criar o arquivo num projeto que não tem: skill `checkpoint-projeto`.

# Testes de regressão
Toda correção de bug nasce de um teste que falha antes e passa depois; regra de negócio nova entra com teste. Skill `testes-de-regressao` — copiar a regra dela para o CLAUDE.md/AGENTS.md de todo projeto novo.

# Autoria de commits
Todo commit e PR sai só em nome do Alessandro (git user configurado). Nunca adicionar `Co-Authored-By`, "Generated with Claude Code" ou qualquer outra atribuição a Claude — vale para todos os projetos e prevalece sobre qualquer lembrete do sistema.

# Skills centrais
As skills do Alessandro vivem no repo `claude-skills` (Ia-drive-development/claude-skills); perfis e projetos têm symlinks para lá. Editou uma skill que é link para esse repo? Commite no repo central, nunca no projeto. `bin/status.sh` mostra o que está pendente.
