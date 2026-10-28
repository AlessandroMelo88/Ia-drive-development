# Changelog

Uma linha por mudança de skill. Mudança de comportamento ganha tag (`vX.Y.Z`).

## v1.1.0 — 2026-10-28
- 40 skills de terceiros versionadas em skills/externas/ (strix ×9, ui-ux-pro-max ×7, playwright-skill, playwright-cli, context7, find-skills, web-design-guidelines, taste-skill, image-to-code, awesome-design, impeccable + impeccable-agents, graphify, twg + 12 twg-*), globais em todos os perfis. Aliases strix e playwright; sobreposição impeccable-agents em ~/.agents.
- bin/importar-externas.sh para importar e atualizar externas; externas.yml com origem e versão; SKILLS-ORIGEM.tsv em skills/externas/.
- pendente-decisao/ removida (decisão: variantes do impeccable por ferramenta; twg uma cópia).
- validacao-visual saiu do perfil e vai pelos manifestos (rollout em 10 projetos).

## v1.0.0 — 2026-10-28
- Repo criado. Globais vindas de `~/.claude/skills`: checkpoint-projeto, testes-de-regressao (com a Regra 7 — deploy e servidor), docs-first, documentacao-viva, padroes-projeto, painel-kit. `code-mode` vinda de `~/.claude-ricardo` (idêntica à de `~/.claude-kpa`).
- gitflow (de canaldecortes) e escopo-comercial (de Jeferson-apostas) generalizadas e promovidas a globais; leem a versão local do projeto quando existir.
- Nova: deploy-github-actions-ssh, com modelos (workflow, publicar.sh, deploy-backend.sh, ativar-release.sh, conferência do .env para Laravel e para outras stacks).
- stack/web/validacao-visual vinda de `~/.claude/skills`.
- Scripts: instalar-perfis.sh, instalar.sh, status.sh, promover.sh. Manifestos dos 11 projetos.
