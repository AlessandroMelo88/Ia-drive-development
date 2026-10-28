#!/usr/bin/env bash
# =============================================================================
# Copia skills de terceiros para skills/externas/<nome>/ (importação inicial e atualização).
#
# Uso: bin/importar-externas.sh [--simular] [nome ...]     (sem nome: todas de externas.yml)
#
# Fonte de cada skill: a 4ª coluna de externas.yml, se houver; senão a primeira cópia FORA do repo
# nos destinos de perfis.yml (pasta real, ou link para fora do repo, resolvido). Se o perfil já
# aponta para o repo, não há o que importar: o instalador da skill escreveu direto aqui pelo link
# (veja o `git diff`).
#
# Atualizar: reinstale pela ferramenta da skill (ex.: npx skills add usestrix/strix), rode este script
# com o nome, revise o git diff, ajuste a versão em externas.yml, commite e rode bin/instalar-perfis.sh
# (a cópia nova que o instalador deixou no perfil vai para skills-backup-<data>/ e volta a ser link).
#
# Não copia lixo gerado: .DS_Store, .twg-install.json (metadado do instalador twg), .coverage,
# __pycache__, *.pyc, node_modules.
# =============================================================================
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_comum.sh"

SIM=""; NOMES=()
for a in "$@"; do case "$a" in --simular) SIM=1 ;; -h|--help) sed -n '2,19p' "$0"; exit 0 ;; *) NOMES+=("$a") ;; esac; done

ENTRADAS="$(yml_lista "$REPO/externas.yml" externas)"
[[ ${#NOMES[@]} -gt 0 ]] || NOMES=($(awk -F' [|] ' '{print $1}' <<< "$ENTRADAS"))
DESTINOS="$(destinos_skills)"
mkdir -p "$REPO/skills/externas"
importadas=0

for nome in "${NOMES[@]}"; do
  linha="$(awk -F' [|] ' -v n="$nome" '$1==n' <<< "$ENTRADAS")"
  [[ -n "$linha" ]] || { aviso "$nome não está em externas.yml (registre a origem antes)"; continue; }
  fonte="$(awk -F' [|] ' '{print $4}' <<< "$linha")"
  [[ -n "$fonte" ]] && fonte="$(expandir "$fonte")"
  if [[ -z "$fonte" ]]; then
    while IFS= read -r d; do
      c="$d/$nome"
      [[ -e "$c" ]] || continue
      fonte="$c"; break
    done <<< "$DESTINOS"
  fi
  if [[ -z "$fonte" || ! -e "$fonte" ]]; then aviso "$nome: nenhuma cópia encontrada nos perfis"; continue; fi
  real="$(cd "$fonte" && pwd -P)"
  case "$real" in
    "$REPO"/*) echo "no-repo    $nome (o perfil já aponta para o repo; nada a importar)"; continue ;;
  esac
  [[ -f "$real/SKILL.md" ]] || { aviso "$nome: $real não tem SKILL.md"; continue; }
  if [[ -n "$SIM" ]]; then echo "importaria $nome  <- $(curto "$real")"; continue; fi
  rsync -a --delete --exclude .DS_Store --exclude .twg-install.json --exclude .coverage \
    --exclude __pycache__ --exclude '*.pyc' --exclude node_modules "$real/" "$REPO/skills/externas/$nome/"
  echo "importada  $nome  <- $(curto "$real")"
  importadas=$((importadas + 1))
done

echo ""; ok "$importadas importada(s). Revise o git diff e rode bin/instalar-perfis.sh"
