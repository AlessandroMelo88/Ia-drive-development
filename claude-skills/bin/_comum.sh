#!/usr/bin/env bash
# Funções compartilhadas pelos scripts de bin/. Compatível com o bash 3.2 do macOS.
# Nenhum caminho fixo: tudo é relativo à raiz do repo ou ao $HOME da máquina.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_BACKUP="${DATA_BACKUP:-$(date +%Y%m%d)}"
IGNORAR_DIFF=(-x .DS_Store -x node_modules -x .git)

info()  { printf '\033[0;34m[INFO]\033[0m %s\n' "$*"; }
ok()    { printf '\033[0;32m[OK]\033[0m %s\n' "$*"; }
aviso() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
erro()  { printf '\033[0;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

# Troca ~ inicial por $HOME.
expandir() { case "$1" in "~") echo "$HOME" ;; "~/"*) echo "$HOME/${1#\~/}" ;; *) echo "$1" ;; esac; }

# Mostra $HOME como ~ na saída.
curto() { case "$1" in "$HOME"*) echo "~${1#$HOME}" ;; *) echo "$1" ;; esac; }

# yml_lista <arquivo> <chave>: itens "  - x" da lista <chave>: (sem comentários).
yml_lista() {
  awk -v k="$2" '
    /^[^[:space:]#][^:]*:/ { sec = $0; sub(/:.*/, "", sec); next }
    sec == k && /^[[:space:]]+-[[:space:]]/ {
      v = $0; sub(/^[[:space:]]+-[[:space:]]+/, "", v); sub(/[[:space:]]+#.*$/, "", v); print v
    }' "$1"
}

# yml_valor <arquivo> <chave>: valor escalar "chave: valor".
yml_valor() {
  awk -v k="$2" '$0 ~ "^"k":" { v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v); print v; exit }' "$1"
}

# É pasta de perfil do Claude Code (e não está em ignorar:)?
eh_perfil() {
  local p="$1" i
  while IFS= read -r i; do [[ "$(expandir "$i")" == "$p" ]] && return 1; done < <(yml_lista "$REPO/perfis.yml" ignorar)
  [[ -d "$p/projects" || -f "$p/history.jsonl" || -d "$p/skills" ]]
}

# Destinos de skills globais já resolvidos (um por linha). Com $1=criar, cria os literais que faltam.
destinos_skills() {
  local e x base pai
  while IFS= read -r e; do
    x="$(expandir "$e")"
    case "$x" in
      *\**)
        base="$(basename "$x")"
        for pai in $(dirname "$x"); do
          [[ -d "$pai" ]] && eh_perfil "$pai" && echo "$pai/$base"
        done ;;
      *) [[ "${1:-}" == criar ]] && mkdir -p "$x"; [[ -d "$x" ]] && echo "$x" ;;
    esac
  done < <(yml_lista "$REPO/perfis.yml" skills_destinos)
  return 0
}

# Skills globais: caminho absoluto de cada pasta das categorias de `globais:` (perfis.yml), menos as
# de `nao_ligar:`.
skills_globais() {
  local cat d nl; nl=" $(yml_lista "$REPO/perfis.yml" nao_ligar | tr '\n' ' ') "
  while IFS= read -r cat; do
    for d in "$REPO/skills/$cat"/*/; do
      [[ -f "$d/SKILL.md" ]] || continue
      [[ "$nl" == *" $(basename "$d") "* ]] && continue
      echo "${d%/}"
    done
  done < <(yml_lista "$REPO/perfis.yml" globais)
  return 0
}

# Alvo do link <destino>/<nome>: a sobreposição de perfis.yml, se houver; senão a própria skill ($3).
alvo_para() {
  local dest="$1/$2" padrao="$3" l esq dir
  while IFS= read -r l; do
    esq="$(expandir "${l%% = *}")"; dir="${l#* = }"
    [[ "$esq" == "$dest" ]] && { echo "$REPO/skills/$dir"; return 0; }
  done < <(yml_lista "$REPO/perfis.yml" sobreposicoes)
  echo "$padrao"
}

# Aliases ("nome = skill") valem só nos perfis do Claude Code.
eh_destino_claude() { case "$1" in */.claude/skills|*/.claude-*/skills) return 0 ;; *) return 1 ;; esac; }
aliases() { yml_lista "$REPO/perfis.yml" aliases; }

# Caminho da skill no repo a partir do nome (procura em todo skills/). Vazio se não existe.
skill_por_nome() {
  local d
  for d in "$REPO"/skills/*/"$1" "$REPO"/skills/stack/*/"$1"; do [[ -f "$d/SKILL.md" ]] && { echo "$d"; return 0; }; done
  return 0
}

# Conteúdo igual (ignorando .DS_Store, node_modules e .git)?
igual() { diff -rq "${IGNORAR_DIFF[@]}" "$1" "$2" >/dev/null 2>&1; }

# Move $1 para <pasta-do-destino>/../skills-backup-<data>/ sem nunca sobrescrever. Imprime o destino.
mover_backup() {
  local alvo="$1" pasta bk n
  pasta="$(dirname "$(dirname "$alvo")")/skills-backup-$DATA_BACKUP"
  [[ "$(basename "$(dirname "$alvo")")" == skills ]] || pasta="$(dirname "$alvo")/skills-backup-$DATA_BACKUP"
  mkdir -p "$pasta"
  bk="$pasta/$(basename "$alvo")"; n=2
  while [[ -e "$bk" || -L "$bk" ]]; do bk="$pasta/$(basename "$alvo")-$n"; n=$((n + 1)); done
  mv "$alvo" "$bk"
  echo "$bk"
}

# ligar <destino> <alvo> [simular]: garante que <destino> é symlink para <alvo>; o que estava lá vai
# para o backup. Imprime o que fez.
ligar() {
  local dest="$1" alvo="$2" sim="${3:-}" bk
  if [[ -L "$dest" && "$(readlink "$dest")" == "$alvo" ]]; then
    echo "ja-ligado  $(curto "$dest")"; return
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ -n "$sim" ]]; then echo "trocaria   $(curto "$dest") (original iria para skills-backup-$DATA_BACKUP)"; return; fi
    bk="$(mover_backup "$dest")"
    ln -s "$alvo" "$dest"
    echo "trocado    $(curto "$dest")  (original em $(curto "$bk"))"
  else
    if [[ -n "$sim" ]]; then echo "ligaria    $(curto "$dest")"; return; fi
    ln -s "$alvo" "$dest"
    echo "ligado     $(curto "$dest")"
  fi
}
