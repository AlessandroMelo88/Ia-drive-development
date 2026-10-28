#!/usr/bin/env bash
# =============================================================================
# Liga as skills globais (categorias de `globais:` em perfis.yml, aliases e sobreposições) e as regras globais (regras/CLAUDE-global.md) em todos os
# destinos de perfis.yml: perfis do Claude Code, ~/.agents/skills (Codex e Gemini), AGENTS.md/GEMINI.md.
#
# Uso: bin/instalar-perfis.sh [--simular] [--sem-regras]
#
#  - Sempre symlink para este repo (nunca cópia): editar a skill em qualquer lugar edita o repo.
#  - O que já existir com o mesmo nome (pasta real, arquivo ou link para outro lugar) é MOVIDO para
#    <perfil>/skills-backup-<AAAAMMDD>/ antes; nada é apagado. DATA_BACKUP=AAAAMMDD fixa a data.
#  - Não toca em nenhuma outra skill do perfil, em synced/ nem em plugins.
#  - Funciona em máquina limpa depois do `git clone`: os caminhos vêm do $HOME e da raiz do repo.
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_comum.sh"

SIM=""; REGRAS=1
for a in "$@"; do case "$a" in
  --simular) SIM=1 ;; --sem-regras) REGRAS=0 ;;
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
  *) erro "opção desconhecida: $a" ;; esac; done

[[ -n "$SIM" ]] && info "Simulação: nada será alterado."
info "Repo: $(curto "$REPO")"

DESTINOS="$(destinos_skills ${SIM:+nao}criar)"
[[ -n "$DESTINOS" ]] || erro "nenhum destino de skills encontrado (veja perfis.yml)"

while IFS= read -r dest; do
  echo ""
  info "Skills globais em $(curto "$dest")"
  if [[ ! -d "$dest" ]]; then
    if [[ -n "$SIM" ]]; then echo "criaria    $(curto "$dest")"; else mkdir -p "$dest"; fi
  fi
  while IFS= read -r skill; do
    ligar "$dest/$(basename "$skill")" "$(alvo_para "$dest" "$(basename "$skill")" "$skill")" "$SIM"
  done < <(skills_globais)
  if eh_destino_claude "$dest"; then
    while IFS= read -r a; do
      alvo="$(skill_por_nome "${a#* = }")"
      [[ -n "$alvo" ]] || { aviso "alias ${a%% = *}: skill ${a#* = } não existe no repo"; continue; }
      ligar "$dest/${a%% = *}" "$alvo" "$SIM"
    done < <(aliases)
  fi
done <<< "$DESTINOS"

if [[ "$REGRAS" -eq 1 ]]; then
  echo ""
  info "Regras globais (regras/CLAUDE-global.md)"
  while IFS= read -r e; do
    x="$(expandir "$e")"
    if [[ ! -d "$(dirname "$x")" ]]; then echo "pulado     $(curto "$x") (CLI não instalado nesta máquina)"; continue; fi
    ligar "$x" "$REPO/regras/CLAUDE-global.md" "$SIM"
  done < <(yml_lista "$REPO/perfis.yml" regras_destinos)
fi

echo ""
ok "Pronto. Confira com bin/status.sh"
