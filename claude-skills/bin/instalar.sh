#!/usr/bin/env bash
# =============================================================================
# Liga no projeto as skills listadas em projetos/<projeto>.yml (além das globais, que vêm pelo perfil).
#
# Uso: bin/instalar.sh <projeto> [caminho-do-projeto] [--simular]
#      bin/instalar.sh --todos [--simular]
#
#  - Cria <projeto>/.claude/skills/<nome> como symlink para este repo e acrescenta
#    /.claude/skills/<nome> ao .git/info/exclude do projeto (local, nunca commitado).
#  - Nunca mexe em skill local do projeto (pasta real) nem em link que aponta para outro lugar:
#    nesses casos para e avisa.
#  - O caminho vem do manifesto (`caminho:`, com ~). Em outra máquina, passe o caminho como 2º
#    argumento ou ajuste o manifesto.
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_comum.sh"

SIM=""; ARGS=()
for a in "$@"; do case "$a" in --simular) SIM=1 ;; -h|--help) sed -n '2,15p' "$0"; exit 0 ;; *) ARGS+=("$a") ;; esac; done
[[ ${#ARGS[@]} -ge 1 ]] || erro "uso: bin/instalar.sh <projeto> [caminho] [--simular] | --todos"

instalar_projeto() {
  local nome="$1" man="$REPO/projetos/$1.yml" caminho="${2:-}" s alvo dest exclude conflitos=0
  [[ -f "$man" ]] || erro "manifesto não encontrado: projetos/$nome.yml"
  [[ -n "$caminho" ]] || caminho="$(expandir "$(yml_valor "$man" caminho)")"
  [[ -d "$caminho" ]] || { aviso "$nome: pasta não existe ($caminho). Pulado."; return; }
  echo ""; info "$nome ($(curto "$caminho"))"

  local lista; lista="$(yml_lista "$man" skills)"
  [[ -n "$lista" ]] || { echo "nada a ligar (só globais)"; return; }

  exclude=""
  if git -C "$caminho" rev-parse --git-dir >/dev/null 2>&1; then
    exclude="$(cd "$caminho" && git rev-parse --path-format=absolute --git-path info/exclude)"
  fi
  [[ -n "$SIM" ]] || mkdir -p "$caminho/.claude/skills"

  while IFS= read -r s; do
    alvo="$REPO/skills/$s"
    [[ -f "$alvo/SKILL.md" ]] || { aviso "skill não existe no repo: skills/$s"; continue; }
    dest="$caminho/.claude/skills/$(basename "$s")"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$alvo" ]]; then
      echo "ja-ligado  $(basename "$s")"
    elif [[ -e "$dest" || -L "$dest" ]]; then
      aviso "conflito: $(curto "$dest") já existe e não é link para o repo. Não mexi. Resolva à mão (ou bin/promover.sh)."
      conflitos=$((conflitos + 1)); continue
    elif [[ -n "$SIM" ]]; then
      echo "ligaria    $(basename "$s")"
    else
      ln -s "$alvo" "$dest"; echo "ligado     $(basename "$s")"
    fi
    if [[ -n "$exclude" && -z "$SIM" ]]; then
      mkdir -p "$(dirname "$exclude")"; touch "$exclude"
      grep -qxF "/.claude/skills/$(basename "$s")" "$exclude" || echo "/.claude/skills/$(basename "$s")" >> "$exclude"
    fi
  done <<< "$lista"
  [[ "$conflitos" -eq 0 ]] || aviso "$nome: $conflitos conflito(s)."
}

if [[ "${ARGS[0]}" == "--todos" ]]; then
  for m in "$REPO"/projetos/*.yml; do instalar_projeto "$(basename "$m" .yml)"; done
else
  instalar_projeto "${ARGS[0]}" "${ARGS[1]:-}"
fi
echo ""; ok "Pronto. Confira com bin/status.sh"
